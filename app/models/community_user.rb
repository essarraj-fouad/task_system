class CommunityUser < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  attr_accessible :community_id, :role, :user_id, :user, :community

  belongs_to :user
  belongs_to :community

  validates :community_id, uniqueness: {scope: :user_id}
  validate :validate_at_least_one_admin
  # before_save :validate_max_members_exceeded
  before_destroy :destroy_has_at_least_one_admin?

  scope :administrators, where(role: 'admin')
  scope :exclude, lambda {|community_user| where(['community_users.id != ?', community_user.id]) unless community_user.new_record?}
  protected
    def validate_at_least_one_admin
      community_users = community.present? ? community.community_users.administrators.exclude(self) : []
      errors.add(:base, :at_least_one_admin) unless community_users.count > 0 or self.role == 'admin'
    end

    def destroy_has_at_least_one_admin?
      community_users = community.community_users.administrators.exclude(self)
      errors.add(:base, :at_least_one_admin) unless community_users.count > 0
      errors.blank?
    end
    
    # def validate_max_members_exceeded
    #   errors.add(:base, :max_members_exceeded) if self.community.members.count >= community.max_users
    # end
end
