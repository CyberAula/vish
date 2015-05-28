class WappAuthToken < ActiveRecord::Base
  attr_accessible :actor_id, :auth_token, :expire_at

  belongs_to :actor

  validates :actor_id, :presence => true
  validates :auth_token, :presence => true, :uniqueness => true
  validates :expire_at, :presence => true

  validate :check_auth_token

  def check_auth_token
    if !self.auth_token.is_a? String
      errors.add(:authentication_token, "Invalid")
    elsif self.auth_token.length < 32
      errors.add(:authentication_token, "Auth token too short")
    else
      true
    end
  end

  before_validation :checkAuthToken
  before_validation :checkExpirationDate


#-------------------------------------------------------------------------------------

  ###########
  # Methods
  ###########

  def expired?
    self.expire_at < Time.now
  end

  def self.deleteExpiredTokens   
    WappAuthToken.where("expire_at < ?", Time.now).each do |token|
      token.destroy
    end
  end

  def self.build_token(length=60)
    begin
      token = SecureRandom.urlsafe_base64(length)
    end while (WappAuthToken.exists?(:auth_token => token))
    token
  end


  private

  def checkAuthToken
    if self.auth_token.nil?
      self.auth_token = WappAuthToken.build_token
    end
  end

  def checkExpirationDate
    if self.expire_at.nil?
      self.expire_at = Time.now + 12.hours
    end
  end

end
