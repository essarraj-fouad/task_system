class Comment < ActiveRecord::Base
  COMMENTABLES = [TaskOccurrence, Payment]
  acts_as_nested_set :scope => [:commentable_id, :commentable_type]

  validates_presence_of :body
  validates_presence_of :user

  scope :no_notification_sent, where('notification_sent = FALSE OR notification_sent IS NULL')

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_voteable

  belongs_to :commentable, :polymorphic => true

  # NOTE: Comments belong to a user
  belongs_to :user

  after_save :send_notifications

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    c = self.new
    c.commentable_id = obj.id
    c.commentable_type = obj.class.base_class.name
    c.body = comment
    c.user_id = user_id
    c
  end

  #helper method to check if a comment has children
  def has_children?
    self.children.size > 0
  end

  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  scope :find_comments_by_user, lambda { |user|
    where(:user_id => user.id).order('created_at DESC')
  }

  # Helper class method to look up all comments for
  # commentable class name and commentable id.
  scope :find_comments_for_commentable, lambda { |commentable_str, commentable_id|
    where(:commentable_type => commentable_str.to_s, :commentable_id => commentable_id).order('created_at DESC')
  }

  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def send_notifications
    commentable.community.members.where(receive_comment_mail: true).each do |user| 
      CommentMailer.posted(commentable.community, user, self).deliver
    end
  end

  # def self.send_notifications
  #   Comment.no_notification_sent.each do |comment|
  #     commentable = comment.commentable
  #     community = commentable.respond_to?(:community) && commentable.community
  #     next unless community
  #     community.members.where(receive_comment_mail: true).each {|user| CommentMailer.posted(user, comment).deliver}
  #     comment.notification_sent = true
  #     comment.save
  #   end
  # end
end


