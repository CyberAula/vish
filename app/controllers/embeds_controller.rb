class EmbedsController < ApplicationController
  before_filter :authenticate_user!, :only => [ :create, :update ]
  before_filter :fill_create_params, :only => [:new, :create]
  include SocialStream::Controllers::Objects
  skip_after_filter :discard_flash, :only => [:create, :update]
  after_filter :notify_teacher, :only => [:create, :update]

  def show
    super do |format|
      format.full {
        @title = resource.title
        render :layout => 'iframe'
      }
    end
  end

  def create
    iframe_url = getIframeURL(params[:embed][:fulltext])
    if iframe_url
      #FullText is an iframe tag.
      #Therefore, we create a Link with the URL of the iframe instead of an embed code.
      urlParams = params[:embed]
      urlParams[:url] = iframe_url
      urlParams[:is_embed] = "true"
      urlParams.delete :fulltext
      urlParams.permit!
      link = Link.new(urlParams)
      link.valid?
      if link.errors.blank? and link.save
        return redirect_to link_path(link)
      else
        unless link.errors.blank?
          if link.errors[:url].present?
            flash[:errors] = I18n.t("link.messages.url_blank")
          elsif link.errors[:title].present?
            flash[:errors] = I18n.t("link.messages.title_blank")
          else
            flash[:errors] = link.errors.full_messages.to_sentence
          end
        end
        return redirect_to home_path
      end
    end
    
    super do |format|
      format.json {
        render :json => resource
      }
      format.js
      format.all {
        if resource.new_record?
          if lookup_context.template_exists?("new", "embeds", false)
            render action: :new
          else
            unless resource.errors.blank?
              if resource.errors[:fulltext].present?
                flash[:errors] = I18n.t("embed.messages.fulltext_blank")
              elsif resource.errors[:title].present?
                flash[:errors] = I18n.t("embed.messages.title_blank")
              else
                flash[:errors] = resource.errors.full_messages.to_sentence
              end
            end
            redirect_to home_path
          end
        else
          discard_flash
          redirect_to embed_path(resource) || home_path
        end
      }
    end
  end

  def update
    super do |format|
      format.json { render :json => resource }
      format.js { render }
      format.all {
        unless resource.errors.blank?
          if resource.errors[:fulltext].present?
            flash[:errors] = I18n.t("embed.messages.fulltext_blank")
          elsif resource.errors[:title].present?
            flash[:errors] = I18n.t("embed.messages.title_blank")
          else
            flash[:errors] = resource.errors.full_messages.to_sentence
          end
        else
          discard_flash
        end
        redirect_to embed_path(resource) || home_path
      }
    end
  end

  def destroy
    destroy! do |format|
      format.html {
        redirect_to url_for(current_subject)
       }
    end
  end


  private

  def allowed_params
    [:fulltext, :width, :height, :live, :language, :license_id, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end

  def fill_create_params
    params["embed"] ||= {}
    params["embed"]["scope"] ||= "0" #public
    params["embed"]["owner_id"] = current_subject.actor_id
    params["embed"]["author_id"] = current_subject.actor_id
    params["embed"]["user_author_id"] = current_subject.actor_id
  end

  def getIframeURL(text)
    nok = Nokogiri::HTML(text)
    iframes = nok.css("iframe")
    if iframes.length == 1
      return iframes[0]["src"]
    else
      return nil
    end
  end

  def notify_teacher
    if VishConfig.getAvailableServices.include? "PrivateStudentGroups"
      author_id = resource.author.user.id
      unless author_id.nil?
        pupil = resource.author.user
        if !pupil.private_student_group_id.nil? && pupil.private_student_group.teacher_notification != "ALL" #REFACTOR: is_pupil?
          teacher = Actor.find(pupil.private_student_group.owner_id).user
          resource_path = document_path(resource) #TODO get full path
          TeacherNotificationMailer.notify_teacher(teacher, pupil, resource_path)
        end
      end
    end
  end

end
