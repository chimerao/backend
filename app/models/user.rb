class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :profiles, dependent: :destroy

  validates :password, length: { minimum: 8 }, if: '!password.nil?'
  validates :password, confirmation: true
  validates :password_confirmation, presence: true, if: '!password.nil?'

  validates :username, presence: true, uniqueness: true
  validates :email,    presence: true, uniqueness: true

  # Just making it easy to read and set default profiles,
  # since :foreign_key and :through are for many relationships.
  #
  def default_profile
    profiles.find_by_id(default_profile_id)
  end

  def default_profile=(profile)
    update_attribute(:default_profile_id, profile.id) if !profile.nil?
  end

end
