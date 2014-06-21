class SubmissionStory < Submission

  has_attached_file :file,
                    storage: :filesystem,
                    url: "/system/submissions/:attachment/:id_partition/:filename"

  validates_attachment_presence :file

  # To have better naming with helpers (namely routes) we need to set
  # the model name to the parent object.
  # It is possible to set this up in the parent, but poses problems
  # during development. Might be good to eventually set it up as outlined here:
  # http://www.alexreisner.com/code/single-table-inheritance-in-rails
  #
  def self.model_name
    Submission.model_name
  end

  def image(size = :thumb_240)
    "/images/1402738190_camill_file1_doc.png"
  end
end
