require "json"
require "open-uri"

class ResultsController < ApplicationController
  def index
    # TODO: return all results with image paths
    # set the instances
    @results = Menu.find(params[:menu_id]).results
    @results_with_data = {}
    # search images for each food
    search_image_for_each_food
  end
  
  def order
    @orders = Result.where("order > ?", 0)

    @menu = Menu.where(user_id: current_user.id)
    url = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&explaintext&redirects=1&titles=udon"

    food_wiki= JSON.parse(open(url).read)
    @food_title = food_wiki["query"]["pages"].values[0]["title"]
    @food_summary = food_wiki["query"]["pages"].values[0]["extract"]
  end

  private

  def search_image_for_each_food
    # boost threads to imcrease performance
    pool = Concurrent::FixedThreadPool.new(10)
    completed = []
    @results.each do |result|
      pool.post do
        # ==========================================
        # ***** FOP DEVELOPMENT purpose *****
        # @results_with_data[result] = [Food::SAMPLE_IMAGES.sample]
        # ***** FOP PRODUCTION purpose *****
        # call searhcimages method and store the returned array
        @results_with_data[result] = SearchImages.call(result.food.name)
        # ==========================================
        completed << 1
      end
    end
    # temporary measure: wait_for_termination does not work well
    sleep(1) unless completed.count == @results.count
    pool.shutdown
    pool.wait_for_termination
  end
  
end
