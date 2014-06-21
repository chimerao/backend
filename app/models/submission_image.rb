class SubmissionImage < Submission

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

  # We need to add width and height to the Image record manually,
  # so we perform this after each save (but not after_save, only in controllers).
  # The reason we cannot do this automatically during save is because
  # a LOT of stuff updates images, and we only need to do this after a
  # create or update.
  #
  # Not to mention, endless loop.
  #
  def save_metadata
    img = Magick::Image.read(file.path).first
    update_attributes(width: img.columns, height: img.rows)
  end

end