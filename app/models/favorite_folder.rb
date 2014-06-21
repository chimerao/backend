class FavoriteFolder < ActiveRecord::Base
  include Folder

  has_many :favorites

  # Adds a favable to the folder. Preferred over manual adding
  # because this allows us to check against various factors.
  #
  def add_favable(favable)
    if favable.profile_can_view?(profile)
      favorite = profile.favorites.create(favable: favable)
      favorites << favorite
      return true
    else
      return false
    end
  end

  # Determines whether or not the folder has a particular favable
  #
  def has_favable?(favable)
    favorites.where(favable_type: favable.class.base_class).pluck(:favable_id).include?(favable.id)
  end
end
