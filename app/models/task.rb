class Task < ActiveRecord::Base
  ALLOCATION_MODES = [:in_turns, :time, :time_all, :voluntary, :user]
  ALLOCATION_MODES_FORM = Task::ALLOCATION_MODES.map {|m| [I18n.t("activerecord.attributes.task.allocation_modes.#{m.to_s}"), m]} 

  TIME_UNITS = {
    days: 1.day,
    weeks: 1.week,
    months: 1.month
  }

  attr_accessible :allocated_user_id, :allocation_mode, :deadline, :description, :interval, :last_occurrence, :name, :repeat, :should_be_checked, :start_on, :time, :user_id, :user_order, :instantiate_automatically, :interval_unit, :repeat_infinite, :deadline_unit
  # attr_accessor :interval_number, :interval_unit, :deadline_number, :deadline_unit
  belongs_to :community
  belongs_to :user # Creator of the task
  belongs_to :allocated_user, class_name: 'User'
  has_many :task_occurrences
  
  validates :name, presence: true, length: {maximum: 50, minimum: 3}
  validates :time, presence: true, :numericality => {:greater_than => 0}
  validates :interval, :numericality => {:greater_than_or_equal_to => 0}
  validates :deadline, :numericality => {:greater_than_or_equal_to => 0}

  validates :deadline_unit, :inclusion => { :in => Task::TIME_UNITS.keys.map(&:to_s) }
  validates :interval_unit, :inclusion => { :in => Task::TIME_UNITS.keys.map(&:to_s) }
  validates :allocation_mode, inclusion: {in: Task::ALLOCATION_MODES.map(&:to_s)}

  after_initialize :set_default_values

  # def interval_value
  #   interval * TIME_UNITS[interval_unit]
  # end

  # def deadline_value
  #   deadline * TIME_UNITS[deadline_unit]
  # end

  def instantiate_in_words
    t_root = 'activerecord.attributes.task.instantiate'
    if instantiate_automatically 
      I18n.t("#{t_root}.#{interval_unit}", count: interval)
    else
      I18n.t("#{t_root}.manual")
    end
  end

  def ordered_members
    ordered_member_ids = self.user_order.split(',').map(&:to_i)
    self.community.members.sort {|a,b| ordered_member_ids.index(a.id) <=> ordered_member_ids.index(b.id) }
  end
  
  private
    def set_default_values
      self.instantiate_automatically = true if self.instantiate_automatically.nil?
      self.user_order ||= self.community.members.map {|m| m.id}.compact.join(',') if self.community.present?
      self.interval ||= 0
      self.deadline ||= 0
      self.time ||= Time.at(0) + 30.minutes
    end

end
