class Task < ActiveRecord::Base

  belongs_to :group
  belongs_to :user, :foreign_key => "assigned_user_id"
  belongs_to :priority
  belongs_to :status

  has_attached_file :task_image, {:styles => { :medium => "390x390#", :thumb => "90x90#" }}.merge(ADD_PP_OPTIONS)

  attr_accessible :description, :raised_user_id, :assigned_user_id, :group_id, :latitude, :longitude, :location, :priority_id, :status_id, :due_date, :complete, :task_image

  geocoded_by :location
  reverse_geocoded_by :latitude, :longitude, :address => :location

  validates :description, :priority_id, :status_id, :due_date, :presence => true
  validates :group_id, :presence => true, :numericality =>  { :only_integer => true }
  validates :raised_user_id, :assigned_user_id, :presence => true, :numericality =>  { :only_integer => true }
  validates :longitude, :numericality => { :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180 }
  validates :latitude, :numericality => { :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90 }

  scope :default_order, -> { order('created_at DESC') }

  before_validation :reverse_geocode, :if => :has_coordinates
  before_validation :geocode, :if => :has_location, :unless => :has_coordinates

  before_save :cleanup

  scope :in_progress, -> { where(:complete => false) }
  scope :complete, -> { where(:complete => true) }
  scope :unarchived, -> { where(:archive => false) }

  def self.check_deadlines
    deadline_tasks = Task.where("due_date = ?", Date.today)
    unless deadline_tasks.empty?
      deadline_tasks.each do |task|
        begin
          Notification.notify_deadline(task.user, task.description).deliver
        rescue Exception => e
          logger.error "Unable to deliver the task deadline email: #{e.message}"
        end
      end
    end

    looming_tasks = Task.where("due_date = ?", Date.today + 4)
    unless looming_tasks.empty?
      looming_tasks.each do |task|
        begin
          Notification.notify_looming(task.user, task.description).deliver
        rescue Exception => e
          logger.error "Unable to deliver the task looming email: #{e.message}"
        end
      end
    end
  end

  def self.tasks_from_groups_joined_by(user)
    group_ids = user.group_ids
    unless group_ids.empty?
      where("group_id IN (#{group_ids.join(", ")})")
    else
      []
    end
  end

  private

  def cleanup
    self.description = self.description.chomp
  end

  def has_coordinates
    self.longitude && self.latitude
  end

  def has_location
    self.location
  end

end
