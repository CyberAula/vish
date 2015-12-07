class RsevaluationController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash

  def start
    evaluationStatus = current_subject.rsevaluation.nil? ? "0" : current_subject.rsevaluation.status
    return redirect_to(user_path(current_subject), :notice => I18n.t("rsevaluation.messages.duplicated")) unless evaluationStatus != "Finished"

    maxUserLos = 5
    @userLos = Rsevaluation.getLosForActor(current_subject,maxUserLos)
    return redirect_to(user_path(current_subject), :alert => I18n.t("rsevaluation.messages.resources")) unless @userLos.length > 3

    #RS settings for the evaluation study
    rsSettings = {:preselection_filter_query => false, :preselection_filter_resource_type => true, :preselection_filter_languages => true, :preselection_filter_own_resources => false, :preselection_authored_resources => true, :preselection_size => 400, :preselection_size_min => 100, :only_context => false, :rs_weights => {:los_score=>0.6, :us_score=>0.2, :quality_score=>0.1, :popularity_score=>0.1}, :los_weights => {:title=>0.2, :description=>0.1, :language=>0.5, :keywords=>0.2}, :us_weights => {:language=>0.2, :keywords => 0.2, :los=>0.6}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0.3, :popularity_score=>0}, :los_filters => {:title => 0, :description => 0, :keywords => 0, :language=>0}, :us_filters => {:language=>0, :keywords => 0, :los=>0}}

    case evaluationStatus
    when "0"
      #No data needed for step1
      render :step1
    when "1"
      #Data for step2
      rsSettingsA = rsSettings
      @recommendationsA = RecommenderSystem.resource_suggestions({:n => 6, :settings => rsSettingsA, :user => current_subject, :user_settings => {}, :user_los => @userLos, :max_user_los => maxUserLos, :models => [Excursion]})
      @randomA = Rsevaluation.getRandom({:n => 6, :ao_ids_to_avoid => @recommendationsA.map{|lo| lo.activity_object.id}})
      @itemsA = (@recommendationsA + @randomA).shuffle
      render :step2
    when "2"
      #Data for step3
      rsSettingsB = rsSettings.recursive_merge({:preselection_filter_languages => false})
      @lo = getBLo({:settings => rsSettingsB, :user_los => @userLos})
      @recommendationsB = RecommenderSystem.resource_suggestions({:n => 6, :settings => rsSettingsB, :user => nil, :user_settings => {}, :lo => @lo, :models => [Excursion]})
      @randomB = Rsevaluation.getRandom({:n => 6, :ao_ids_to_avoid => @recommendationsB.map{|lo| lo.activity_object.id}})
      @itemsB = (@recommendationsB + @randomB).shuffle
      render :step3
    else
      return redirect_to(user_path(current_subject), :alert => "Evaluation at wrong state. Please contact with the ViSH team.")
    end
  end

  #Redirect to the corresponding step
  def step
    case params[:step]
    when "1"
      step1
    when "2"
      step2
    when "3"
      step3
    else
      redirect_to "/rsevaluation"
    end
  end

  #Save step1
  def step1
    e = Rsevaluation.new
    e.actor_id = Actor.normalize_id(current_subject)
    e.status = "1"
    e.data = {}.to_json
    e.save!
    redirect_to "/rsevaluation"
  end

  #Save step2
  def step2
    dataA = JSON.parse(params["data"]) rescue {}
    #Data validation.
    errors = []
    errors << "Missing data" if dataA["recommendationsA"].blank? or dataA["randomA"].blank? or dataA["relevances"].blank? or dataA["userLos"].blank?
    errors << "Incorrect number of items" if dataA["recommendationsA"].length!=6 or dataA["randomA"].length!=6
    errors << "Missing relevances" if dataA["relevances"].keys.compact.length!=(dataA["recommendationsA"].length+dataA["randomA"].length)
    errors << "Incorrect relevances" unless dataA["recommendationsA"].map{|h| dataA["relevances"][h["id"]]}.select{|r| r.nil?}.blank? and dataA["randomA"].map{|h| dataA["relevances"][h["id"]]}.select{|r| r.nil?}.blank?

    return redirect_to("/rsevaluation", :alert => errors.first) unless errors.blank?

    data = {}
    data["A"] = dataA
    data["user_profile"] = {}
    data["user_profile"]["language"] = current_subject.language
    data["user_profile"]["tags"] = current_subject.tag_list
    data["user_profile"]["los"] = dataA["userLos"]
    e = current_subject.rsevaluation
    e.data = data.to_json
    e.status = "2"
    e.save!
    redirect_to "/rsevaluation"
  end

  #Save step3
  def step3
    dataB = JSON.parse(params["data"]) rescue {}
    #Data validation.
    errors = []
    errors << "Missing data" if dataB["recommendationsB"].blank? or dataB["randomB"].blank? or dataB["relevances"].blank? or dataB["BLo"].blank?
    errors << "Incorrect number of items" if dataB["recommendationsB"].length!=6 or dataB["randomB"].length!=6
    errors << "Missing relevances" if dataB["relevances"].keys.compact.length!=(dataB["recommendationsB"].length+dataB["randomB"].length)
    errors << "Incorrect relevances" unless dataB["recommendationsB"].map{|h| dataB["relevances"][h["id"]]}.select{|r| r.nil?}.blank? and dataB["randomB"].map{|h| dataB["relevances"][h["id"]]}.select{|r| r.nil?}.blank?

    return redirect_to("/rsevaluation", :alert => errors.first) unless errors.blank?

    e = current_subject.rsevaluation
    data = JSON.parse(e.data)
    data["B"] = dataB
    data["lo_profile"] = dataB["BLo"]

    e.data = data.to_json
    e.status = "Finished"
    e.save!

    redirect_to(user_path(current_subject), :notice => I18n.t("rsevaluation.messages.success"))
  end


  private

  def getBLo(options={})
    return nil unless options[:user_los]
    current_subject.tag_array_cached = current_subject.tag_array
    options[:user_los].map{|pastLo| pastLo.tag_array_cached = pastLo.tag_array}
    similarity = []
    candidateLos = (ActivityObject.find_all_by_id(Vish::Application.config.APP_CONFIG["recommender_system"][:evaluation][:candidate_los]).compact.map{|ao| ao.object}.compact rescue options[:user_los])
    candidateLos.each do |lo|
      lo.tag_array_cached = lo.tag_array
      similarity << RecommenderSystem.userSimilarityScore(current_subject,lo,options)
    end
    return candidateLos[similarity.find_index(similarity.max)]
  end

end
  