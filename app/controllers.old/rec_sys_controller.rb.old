class RecSysController < ApplicationController
  before_filter :authenticate_user!, :only => [ :data, :timestamp ]
  before_filter :profile_subject!, :only => :actor

  # Get the recommended Learning Objects (LOs) and contacts for current user
  def data 
    data = Hash.new
    recsys_contacts = current_subject.contact_suggestions(50)
    recsys_los = current_subject.excursion_suggestions(100)
    rec_users = [];
    rec_los = [];
   
    #
    # Fill empty recs for testing purpose
    #
    if recsys_contacts.empty?
      9.times do |num|
        recsys_contacts.push(Contact.find_by_id(num));
      end
    end 

    if recsys_los.empty?
      4.times do |num|
        recsys_los.push(Document.find_by_id(num));
      end
      6.times do |num|
        recsys_los.push(Excursion.find_by_id(num));
      end
    end

    #Get user and LOs render information
    recsys_contacts.each do |contact|
      user = Hash.new
      user["id"]=contact.receiver.id;
      user["contact_id"]=contact.id;
      user["name"]=contact.receiver.name;
      user["avatar"]=contact.receiver.logo.url;
      user["followers"]=contact.receiver_subject.followers.count;
      user["following"]=contact.receiver_subject.followings.count;
      rec_users.push(user);
    end

    recsys_los.each do |recsys_lo|
      if recsys_lo
        lo = Hash.new
        lo["id"]=recsys_lo.id;

        if recsys_lo.excursion
          lo["content_type"]="excursion";
          lo["name"]=recsys_lo.title;
        else
          lo["name"]=recsys_lo.file_file_name;
          lo["content_type"]=recsys_lo.file_content_type;
        end
        
        lo["author"]=recsys_lo.author.name;

        rec_los.push(lo);
      end
    end

    data["rec_users"] = rec_users;
    data["rec_los"] = rec_los;

    respond_to do |format|
      format.html { render :text => "Request JSON to get recomended data" } 
      format.json { render :json => data }
    end
  end

  def timestamp
    timestamp = Hash.new
    if Site.current.config[:RecSysTimestamp]
      timestamp["timestamp"] = Site.current.config[:RecSysTimestamp]
    else
      timestamp["timestamp"] = "Error: No timestamp founded";
    end
    respond_to do |format|
      format.html { render :text => "Request JSON to get RecSysTimestamp" } 
      format.json { render :json => timestamp }
    end
  end

  def onSocialContextGenerated
    Site.current.config[:RecSysTimestamp] = Time.now
    Site.current.save!
    respond_to do |format|
      format.html { render :text => Time.now } 
      format.json { render :json => Time.now }
    end
  end
end