class JournalImage < ActiveRecord::Base

  belongs_to :journal
  belongs_to :profile

  # Paperclip
  has_attached_file :image,
                    styles: {
                      pixels_600: '600x600>',
                      pixels_400: '400x400>',
                      pixels_240: '240x240>'
                    }

  validates_attachment_presence     :image
  validates_attachment_size         :image, less_than: 1.megabyte
  validates_attachment_content_type :image,
                                    content_type: [
                                      'image/gif',
                                      'image/png',
                                      'image/x-png',
                                      'image/jpg',
                                      'image/jpeg',
                                      'image/pjpeg'
                                    ]
end
