# encoding: utf-8

class PrivateStudentGroup < ActiveRecord::Base
  belongs_to :private_teacher, foreign_key: "owner_id", class_name: "Actor"
  has_many :private_students, class_name: "User"

  validates :owner_id, :presence => true
  validates :name, :presence => true

  after_destroy :remove_accounts

  acts_as_xlsx

  def createGroupForSubject(subject,n=20)
    self.owner_id = subject.actor_id
    saved = self.save
    return self unless saved

    usersData = {}

    usernameBase = I18n.t("private_student.account_name")
    emailServer = "vishub.org"

    n.times do |i|
      user = User.new
      user.name = usernameBase + "-" + i.to_s
      user.email = user.name + "-g" + self.id.to_s + "@" + emailServer
      require 'securerandom'
      user.password = SecureRandom.hex(4)
      user.password_confirmation = user.password
      user.private_student_group_id = self.id
      user.roles.push(Role.find_by_name("PrivateStudent"))
      user.scope = 1
      user.save!
      user.activity_object.relation_ids = [Relation::Private.instance.id]

      #Disable mail notifications
      notification_settings = user.notification_settings || {}
      notification_settings[:someone_adds_me_as_a_contact] = false
      notification_settings[:someone_confirms_my_contact_request] = false
      notification_settings[:someone_likes_my_post] = false
      notification_settings[:someone_comments_on_my_post] = false
      user.actor.notification_settings = notification_settings
      user.actor.save!

      usersData[user.email] = user.password
    end

    self.users_data = usersData.to_json
    self.save!
  end

  def credentials
    credentials = JSON.parse(self.users_data) rescue {}
  end

  def title
    name
  end

  def resources(types=nil)
    types = VishConfig.getAvailableResourceModels if types.nil?
    self.private_students.map{|ps| ActivityObject.authored_by(ps).where(:object_type => types)}.flatten.map{|ao| ao.object}.compact
  end

  def excursions
    resources("Excursion")
  end

  def public_excursions
    resources("Excursion").reject{|e| e.draft}
  end

  private

  def remove_accounts
    self.private_students.map{|ps| ps.destroy}
  end


end
