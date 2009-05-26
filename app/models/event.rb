class Event < ActiveRecord::Base

  named_scope :without_tickets, :conditions => 'id not in (select event_id from tickets)'

  has_many                :tickets, :dependent => :delete_all
  
  has_many                :districts, :through => :tickets, :uniq => true
  has_many                :occasions, :order => "date ASC"
  has_and_belongs_to_many :tags
  belongs_to              :culture_provider
  has_one                 :questionaire

  validates_presence_of :from_age, :to_age, :description
  validates_numericality_of :from_age, :to_age, :only_integer => true

  # Ticket states

  CREATED          = 0
  ALLOTED_GROUP    = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  NON_BOOKABLE     = 4


  def self.visible_events_by_userid(u)
    today = Date.today
    u = u.to_i
    events = Event.find_by_sql "select * from events where show_date < '#{today.to_s}' and id in ( select distinct event_id from tickets,groups_users where user_id=#{u} and tickets.group_id = groups_users.group_id)"
    return events
  end

end
