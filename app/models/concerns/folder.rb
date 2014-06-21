require 'active_support/concern'

module Folder
  extend ActiveSupport::Concern

  included do
    belongs_to :profile

    validates :name,
              presence: true,
              length: { maximum: 80 },
              uniqueness: { scope: :profile_id }

    before_validation :set_url_name
    before_destroy :check_permanence
  end

  private

    # We need url_title to be a unique, URI-safe identifier.
    #
    def set_url_name
      self.url_name = name.gsub(/\s/, "-").gsub(/[^a-zA-Z0-9-]/, "").downcase
    end

    # Make sure permanent folders cannot be destroyed
    #
    def check_permanence
      return false if is_permanent?
    end
end