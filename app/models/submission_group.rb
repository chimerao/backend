class SubmissionGroup < Submission
  class SubmissionGroupRecursionError < StandardError
  end

  has_many :submissions

  validate :cannot_be_in_submission_group

  before_update :check_submission_group_id
  before_destroy :clear_submissions

  # To have better naming with helpers (namely routes) we need to set
  # the model name to the parent object.
  # It is possible to set this up in the parent, but poses problems
  # during development. Might be good to eventually set it up as outlined here:
  # http://www.alexreisner.com/code/single-table-inheritance-in-rails
  #
  def self.model_name
    Submission.model_name
  end

  def submission_image
    submissions.where(type: 'SubmissionImage').first
  end

  def image(options)
    submission_image.image(options)
  end

  # Convenience methods to add and remove a submisson to a group,
  # and perform any sort of validations we want to.
  #
  def add_submission(sub)
    if sub.submission_group
      sg = sub.submission_group
    end
    sub.update_attribute(:submission_group_id, self.id)
    if sg && sg.submissions.count < 2
      sg.destroy
    end
  end

  def remove_submission(sub)
    if submissions.count <= 2
      self.destroy
    else
      sub.update_attribute(:submission_group_id, nil)
    end
  end

  private

    def clear_submissions
      submissions.each do |sub|
        sub.update_attribute(:submission_group_id, nil)
      end
    end

    def cannot_be_in_submission_group
      errors.add(:submission_group_id, 'Cannot be a part of a submission group.') unless submission_group.nil?
    end

    def check_submission_group_id
      raise SubmissionGroupRecursionError, "Cannot have nested submission groups" unless submission_group_id.nil?
    end
end
