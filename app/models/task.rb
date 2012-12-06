class Task < ActiveRecord::Base
  ALLOCATION_MODES = [:in_turns, :time, :time_all, :voluntary, :user]
  ALLOCATION_MODES_FORM = Task::ALLOCATION_MODES.map {|m| [I18n.t("activerecord.attributes.task.allocation_modes.#{m.to_s}"), m]} 

  TIME_UNITS = {
    days: 1.day,
    weeks: 1.week,
    months: 1.month
  }

  attr_accessible :allocated_user_id, :allocation_mode, :deadline, :description, :interval, :next_occurrence, :name, :repeat, :should_be_checked, :time, :user_id, :user_order, :instantiate_automatically, :interval_unit, :repeat_infinite, :deadline_unit

  belongs_to :community
  belongs_to :user # Creator of the task
  belongs_to :allocated_user, class_name: 'User'
  has_many :task_occurrences
  
  validates :name, presence: true, length: {maximum: 50, minimum: 3}
  validates :time, presence: true, :numericality => {:greater_than => 0}
  validates :interval, :numericality => {:greater_than => 0}
  validates :deadline, presence: true, :numericality => {:greater_than_or_equal_to => 0}
  validates :user_order, format: {with: /(\d+)(,\d+)*/} 
  validates :repeat, presence: true, :numericality => {:greater_than_or_equal_to => 0}
  validates :deadline_unit, presence: true, :inclusion => { :in => Task::TIME_UNITS.keys.map(&:to_s) }
  validates :interval_unit, :inclusion => { :in => Task::TIME_UNITS.keys.map(&:to_s) }
  validates :allocation_mode, inclusion: {in: Task::ALLOCATION_MODES.map(&:to_s)}

  after_initialize :set_default_values

  scope :to_schedule, where(instantiate_automatically: true).where("tasks.next_occurrence <= UTC_TIMESTAMP()").where("tasks.repeat_infinite = true OR tasks.repeat > 0")

  class << self
    def schedule_upcoming_occurrences
      Task.to_schedule.each &:schedule
    end 
  end

  def schedule task_occurrences_params = {}
    ActiveRecord::Base.transaction do
      task_occurrence = task_occurrences.build task_occurrences_params
      task_occurrence.deadline = Time.now + deadline_time
      task_occurrence.time_in_minutes = self.time_in_minutes
      task_occurrence.allocate if task_occurrence.user.nil?

      self.next_occurrence += self.interval_time
      self.repeat-=1 if !self.repeat_infinite and self.repeat > 0
      self.save!
    end
  end

  def next_allocated_user
    case allocation_mode
      when 'in_turns' then allocate_in_turns
      when 'time' then allocate_by_time
      when 'time_all' then allocate_by_time_all
      when 'user' then allocated_user
    end
  end

  def instantiate_in_words
    t_root = 'activerecord.attributes.task.instantiate'
    if instantiate_automatically 
      I18n.t("#{t_root}.#{interval_unit}", count: interval)
    else
      I18n.t("#{t_root}.manual")
    end
  end

  def interval_time
    eval "#{interval}.#{interval_unit}" if TIME_UNITS.keys.include?(interval_unit.to_sym)
  end

  def deadline_time
    eval "#{deadline}.#{deadline_unit}" if TIME_UNITS.keys.include?(deadline_unit.to_sym)
   
  end

  def ordered_members
    # Sort members based on the attribute 'user_order' (list of ids)
    ordered_member_ids = self.user_order.split(',').map(&:to_i)
    self.community.members.sort {|a,b| ordered_member_ids.index(a.id) <=> ordered_member_ids.index(b.id) }
  end

  def time_in_minutes
    time.hour * 60 + time.min
  end

  
  private
    def set_default_values
      self.instantiate_automatically = true if self.instantiate_automatically.nil?
      self.user_order ||= self.community.members.map {|m| m.id}.compact.join(',') if self.community.present?
      self.interval ||= 1
      self.deadline ||= 1
      self.time ||= Time.at(0) + 30.minutes
      self.next_occurrence ||= Date.today
      self.repeat ||= 0
    end

    def allocate_in_turns
      ordered_id_list = user_order.split(',')
      previous_occurrence = task_occurrences.latest.first
      previous_user_id = (previous_occurrence.present? ? previous_occurrence.user.id : ordered_id_list.last)
      next_user_id = ordered_id_list.include?(previous_user_id.to_s) ? ordered_id_list.rotate(ordered_id_list.index(previous_user_id.to_s) + 1).first : nil

      # allocate to creater of task when next user is not found
      community.members.find_by_id(next_user_id) || user
    end

    def allocate_by_time
      least_time_user_id = task_occurrences.group(:user_id).order(:sum_time_in_minutes).limit(1).sum(:time_in_minutes).keys.first
      User.find least_time_user_id
    end

    def allocate_by_time_all
      least_time_user_id = TaskOccurrence.for_community(community).group('task_occurrences.user_id').order(:sum_time_in_minutes).limit(1).sum(:time_in_minutes).keys.first
      User.find least_time_user_id
    end

end
