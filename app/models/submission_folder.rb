class SubmissionFolder < ActiveRecord::Base
  include Folder

  has_and_belongs_to_many :filters, -> { uniq }
  has_and_belongs_to_many :submissions, -> { uniq }

  # Preferred method for adding a submission. This allows
  # checks to be made against various factors.
  #
  def add_submission(sub)
    if sub.collaborators.include?(profile)
      filters.each do |filt|
        sub.filters << filt
      end
      submissions << sub
      return true
    else
      return false
    end
  end

  # Convience method that checks to see if the folder
  # contains a particular submission.
  def has_submission?(sub)
    submissions.include?(sub)
  end
end
