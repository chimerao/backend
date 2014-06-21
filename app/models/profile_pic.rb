# ==A ProfilePic is a picture for a User.
#
# ===A ProfilePic record has the following fields:
#
# id:: ID of the record
# profile_id:: The profile that owns the userpic.
# title:: The title of the ProfilePic.
# is_default:: Designates the ProfilePic as the default one for the Profile. (boolean)
#
class ProfilePic < ActiveRecord::Base

  belongs_to :profile

  has_many :comments
  has_many :submissions

  AVAILABLE_PIXEL_SIZES = [48, 52, 64, 80, 96, 128, 256, 384, 512]
  CROPPED_PIXEL_SIZES = [48, 52, 64]
  styles = {};
  AVAILABLE_PIXEL_SIZES.each do |psize|
    style = "#{psize}x#{psize}"
    style << (CROPPED_PIXEL_SIZES.include?(psize) ? '#' : '>')
    styles["pixels_#{psize}".to_sym] = style
  end

  # Paperclip
  has_attached_file :image,
                    styles: styles,
                    default_url: "/images/no_userpic_:style.gif"

  validates_attachment_presence :image
  validates_attachment_size :image, less_than: 500.kilobytes
  validates_attachment_content_type :image,
                                    content_type: [
                                      'image/gif',
                                      'image/png',
                                      'image/x-png',
                                      'image/jpg',
                                      'image/jpeg',
                                      'image/pjpeg'
                                    ]

  after_create :check_for_default_pic
  after_destroy :ensure_default_pic

  def title
    self[:title] || attributes['image_file_name']
  end

  # Makes the ProfilePic default for the Profile while removing
  # is_default from other pics.
  #
  def make_default!
    pics = profile.profile_pics.where(is_default: true)
    pics.each { |pic| pic.update_attribute(:is_default, false) }
    update_attribute(:is_default, true)
  end

  private

    # If there are no default user pics, make a newly created
    # one the default.
    #
    def check_for_default_pic
      make_default! if profile.default_profile_pic.new_record?
    end

    # If the default user pic gets destroyed, make sure
    # a new one is set from existing.
    #
    def ensure_default_pic
      if profile.default_profile_pic.new_record? and profile.profile_pics.count > 0
        profile.profile_pics.first.make_default!
      end
    end
end
