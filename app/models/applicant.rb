class Applicant < ActiveRecord::Base

	has_many :volunteers
  attr_accessible :email, :name, :password, :password_confirmation, :remember_digest, :admin, :activation_digest, :activated, :activated_at, :reset_digest, :reset_sent_at
  attr_accessor :remember_token, :activation_token, :reset_token
	before_save :downcase_email
	before_create :create_activation_digest
	validates :name, presence: true, length: {maximum: 50}
	VALID_EMAIL_REGEX= /\A[\w\.\-]+\@[a-z\d\.\-]+\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 255}, 
						format: {with: VALID_EMAIL_REGEX},
						uniqueness: {case_sensitive: false}
	has_secure_password
	validates :password, length:{minimum: 6}, allow_blank: true

	def downcase_email
		self.email=email.downcase
	end
	
	def create_activation_digest
		self.activation_token=Applicant.new_token
		self.activation_digest=Applicant.digest(activation_token)
	end
	
	private :downcase_email, :create_activation_digest
		
	def Applicant.digest(string)
    cost =  BCrypt::Engine::MIN_COST #todo: no min_cost error
    BCrypt::Password.create(string, cost: cost)
  end
  
  def Applicant.new_token
    SecureRandom.urlsafe_base64
  end
  
  def remember
  	self.remember_token=Applicant.new_token
  	update_attribute(:remember_digest,Applicant.digest(remember_token))
  end
  
  def authenticated?(attribute, token)
  	digest=send("#{attribute}_digest")
  	return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end
  
  def forget
  	update_attribute(:remember_digest, nil)
  end
  
  def is_admin?
  	return false if self.nil?
  	self.admin?
  end
  
  def activate
  	update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end
  
  def send_activation_email
  	ApplicantMailer.account_activation(self).deliver
  end
  
  def create_reset_digest
    self.reset_token = Applicant.new_token
    update_attribute(:reset_digest,  Applicant.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end
  
  def send_password_reset_email
    ApplicantMailer.password_reset(self).deliver
  end
  
  def password_reset_expired?
  	reset_sent_at < 2.hours.ago
  end
  
end














