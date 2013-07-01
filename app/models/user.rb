require 'digest/sha1'

# Model for a user in the system.
class User < ActiveRecord::Base

  has_and_belongs_to_many :roles
  has_and_belongs_to_many :culture_providers
  has_many :role_applications, :order => "updated_at DESC", :include => [ :role ], :dependent => :destroy

  has_many :allotments, :dependent => :nullify
  has_many :tickets, :dependent => :nullify
  has_many :occasions, :through => :tickets, :uniq => true
  has_many :groups, :through => :tickets, :uniq => true do
    def find_by_occasion(occasion)
      find :all, :conditions => [ " tickets.occasion_id = ? ", occasion.id ]
    end
  end

  has_many :notification_requests, :dependent => :destroy

  has_and_belongs_to_many :districts
  
  validate :username_unique,
    :on => :create,
    :message => "Användarnamnet är redan taget"

  validates_presence_of :username,
    :message => "Användarnamnet får inte vara tomt"
  validates_presence_of :password,
    :message => "Lösenordet får inte vara tomt"
  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_presence_of :email,
    :message => "Epostadressen får inte vara tom"
  validates_format_of :email,
    :with => /[^@]+@[^@]+/,
    :message => "Epostadressen måste vara en giltig epostadress"
  validates_presence_of :cellphone,
    :message => "Mobilnumret får inte vara tomt"
  validates_uniqueness_of :username,
    :message => "Användarnamnet är redan taget"
  validates_confirmation_of :password,
    :message => "Lösenordsbekräftelsen matchar inte lösenordet"
  validates_presence_of :district_ids,
    :message => "Minst en stadsdel måste väljas"

  # The id and salt is automatically generated and should not be changed.
  attr_protected :id, :salt


  # Filters a find call.
  #
  # Supported keys are: <tt>:district_id</tt>
  def self.filter(filter, page, order)
    if filter.blank?
      return paginate(:page => page, :order => order)
    else
      conditions = [ " 1=1 " ]

      if filter.has_key?(:district_id)
        conditions[0] << " and users.id in (select user_id from districts_users where district_id = ?) "
        conditions << filter[:district_id]
      end

      if filter.has_key?(:name)
        name_query = "%#{filter[:name]}%"
        conditions[0] << " and (users.name ilike ? or users.username ilike ?) "
        conditions << name_query
        conditions << name_query
      end

      return paginate(:conditions => conditions, :page => page, :order => order)
    end
  end

  # Returns true if this user is authenticated when using the given password
  def authenticate(password)
    User.encrypt(password, self.salt) == self.password
  end

  # Returns the user with the given name if authentication using the username
  # and password succeeds.
  def self.authenticate(username, password)
    u = find :first, :conditions => { :username => username }
    
    return nil if u.nil?
    return u if u.authenticate(password)
    
    nil
  end

  def get_username
    if APP_CONFIG[:ldap]
      return self.username.sub(APP_CONFIG[:ldap][:username_prefix] , "")
    else
      return self.username
    end
  end

  # Returns the bookings a user has made
  def bookings
    bookings = []

    self.occasions.each do |o|
      Ticket.find(:all ,
        :select => "distinct group_id" ,
        :conditions => { :user_id => self.id , :occasion_id => o.id }
      ).each do |t|
        bookings << { "occasion" => o , "group" => t.group }
      end
    end

    return bookings
  end

  # Returns true if this user has one of the given roles
  def has_role?(*rs)
    @has_role_cache ||= {}

    rs.each do |r|
      if @has_role_cache[r].nil?
        @has_role_cache[r] = roles.exists? [ "lower(name) = ?", r.to_s.downcase ]
      end
      return true if @has_role_cache[r]
    end
    return false
  end

  # Returns true if the user can administrate the given entity.
  # Used to check if a user can administrate a given culture provider
  def can_administrate?(e)
    case e
    when CultureProvider
      return has_role?(:admin) || (has_role?(:culture_worker) && culture_providers.include?(e))
    else
      return false
    end
  end

  # Returns true if this user has booking privileges
  def can_book?
    return has_role?(:admin, :booker)
  end
  # Returns true if this user can view bookings
  def can_view_bookings?
    return has_role?(:admin, :booker, :coordinator)
  end

  
  # Sets the password of a user.
  #
  # This method generates a new salt if there are no salt, and encrypts
  # the password.
  def password=(pass)
    if pass && pass.length > 0
      self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
      write_attribute :password, User.encrypt(pass, self.salt)
    end
  end

  # Accessor for the password confirmation used in the UI.
  def password_confirmation=(pass)
    if pass && pass.length > 0
      self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
      @password_confirmation = User.encrypt(pass, self.salt)
    end
  end

  # Sets all password related data to nil.
  def reset_password
    self.salt = nil
    write_attribute :password, nil
    @password_confirmation = nil
  end


  # Generates a random request key
  def generate_request_key
    self.request_key = User.random_string(APP_CONFIG[:request_key_length])
  end

  # Resets the user's password to a randomly generated password
  def generate_new_password
    pw = User.random_string(APP_CONFIG[:generated_password_length])
    self.reset_password()
    self.password = pw
    self.password_confirmation = pw
    self.save!

    return pw
  end

  
  private

  # Encrypts a password and a salt using SHA1
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  # Generates a random string of the given length.
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size - 1)] }
    return newpass
  end

  def username_unique
    if APP_CONFIG[:ldap]
      prefix = APP_CONFIG[:ldap][:username_prefix] 
    else
      prefix = ""
    end
    if User.find_by_username("#{prefix}#{username}") || User.find_by_username(username.sub(prefix , ""))
      self.errors.add(:username, :taken , :message => "Användarnamnet är redan taget" )
    end
  end

end
