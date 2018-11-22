class MenusController < ApplicationController
  def new
    @menu = Menu.new
  end

  def create
    # ==========================================
    # ***** FOP DEVELOPMENT purpose *****
    detect_words = "-7 チキンナンバン690\nかきあげ690 |\n山田醤油\nおでん盛合せ690|みりん干し,590モモステーキ\n大根玉子竹輪なると11唐揚げ 590\nちくわぶつみれさつま揚\nおろし葱ソース\nサーモンハラス焼590-チューリップ唐揚げ-\nワカサギ天ぷら490\n芝海老かき揚げ590\nレモンバター焼き690\n:\n2本290"
    words = RefineWords.call(detect_words)
    # ***** FOP PRODUCTION purpose *****
    # words = GoogleCloudVisionJob.perform_now(params[:menu][:photo].tempfile.path)
    # ==========================================

    # make new instance without any params on purpose
    @menu = Menu.new
    @menu.user = current_user
    if @menu.save!
      # split the job to increase performance
      StoreImageInCloudinaryJob.perform_later(@menu, menu_params[:photo].tempfile.path)
      sleep(0.1) unless words
      create_result_instances(@menu, words)
      redirect_to menu_results_path(@menu)
    else
      render 'new'
    end
  end

  private

  def create_result_instances(menu, words)
    # create result instance
    # create food instance if it's new
    words.each do |word|
      food = Food.find_by_name(word) || Food.create(name: word)
      Result.create!(menu_id: menu.id, food_id: food.id)
    end
  end

  def menu_params
    params.require(:menu).permit(:photo)
  end
end
    # temporary memo
    # detect words array from the photo: call DetectWords.call method
    # refine each word
    # ==========================================
    # ***** FOP DEVELOPMENT purpose *****
    # detect_words = "00000000000 1000\n本日のおすすめ\n播磨産生カキ\nお刺身盛合せ\n秋田しいたけ\nピクルス\n天ぷら\nマヨチーズ焼き5 9\nサーモンとキノコ"
    # ***** FOP PRODUCTION purpose *****
    # detect_words = DetectWords.call(menu.photo.metadata["url"])
    # ==========================================
    # refined_words = RefineWords.call(detect_words)
