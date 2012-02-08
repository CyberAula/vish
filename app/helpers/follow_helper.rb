module FollowHelper

  def is_my_follower?(subject)
    not current_subject.received_contacts.find(subject).blank?
  end

  def am_i_following?(subject)
    not current_subject.sent_contacts.find(subject).blank?
  end

end
