class User < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :registerable, :timeoutable

  validates :name, presence: true, length: {minimum: 2, maximum: 40}
  validates :email, presence: true, length: {minimum: 2, maximum: 40}
  validates :global_role, presence: true

  has_many :community_users, dependent: :destroy
  has_many :communities, through: :community_users
  has_many :created_communities, class_name: 'Community', foreign_key: 'creator_id'
  has_many :admin_communities, through: :community_users, source: :community, class_name: 'Community', conditions: {role:  'admin'}
  has_many :normal_communities, through: :community_users, source: :community,class_name: 'Community', conditions: {role:  'normal'}

  has_many :invitation_requests, class_name: 'Invitation', foreign_key: 'invitor_id', dependent: :destroy
  has_many :invitations, class_name: 'Invitation', foreign_key: 'invitee_id', dependent: :destroy

  has_many :tasks
  has_many :task_occurrences, dependent: :destroy
  has_many :allocated_tasks, class_name: 'Task', foreign_key: 'allocated_user_id'

  has_many :grocery_items #Created by this user

  has_attached_file :avatar, styles: {small: "40x40>", thumb: "100x100>", large: "300x300>" }

  scope :unconfirmed, where("confirmed_at IS NULL")
  USER_ROLES = [:normal, :admin]

  def confirmed?
    confirmed_at.present?
  end

  def global_admin?
    global_role == 'admin'
  end

end
