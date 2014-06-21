require 'test_helper'

class FavoriteFolderTest < ActiveSupport::TestCase

  test "url name set before create" do
    folder = FavoriteFolder.create(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    assert_equal 'pantsless-dragons', folder.url_name
  end

  test "url name must be unique per profile" do
    FavoriteFolder.create(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    folder = FavoriteFolder.new(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    assert_no_difference 'FavoriteFolder.count' do
      folder.save
    end
    assert_not folder.valid?
    folder = FavoriteFolder.new(profile: profiles(:dragon_profile_2), name: 'Pantsless Dragons')
    assert_difference 'FavoriteFolder.count' do
      folder.save
    end
  end

  test "permanent favorite folders cannot be destroyed" do
    assert_no_difference 'FavoriteFolder.count' do
      favorite_folders(:dragon_favorite_folder).destroy
    end
  end

  test "add favable" do
    @profile = profiles(:raccoon_profile_1)
    @submission = submissions(:dragon_image_1)
    assert_difference 'Favorite.count' do
      @profile.favorite_folder.add_favable(@submission)
    end
    @profile.reload
    assert @profile.has_faved?(@submission)
  end

  test "add favable make sure favorite can be viewed before adding" do
    @profile = profiles(:raccoon_profile_1)
    @submission = submissions(:dragon_friend_submission_1)
    assert_no_difference 'Favorite.count' do
      @profile.favorite_folder.add_favable(@submission)
    end
    @profile.reload
    assert_not @profile.has_faved?(@submission)
  end

  test "add favable should put favorite in proper folder" do
    @profile = profiles(:raccoon_profile_1)
    @submission = submissions(:dragon_image_1)
    @favorite_folder = favorite_folders(:raccoon_raccoons_folder)
    @favorite_folder.add_favable(@submission)
    @profile.reload
    assert_not @profile.favorite_folder.has_favable?(@submission)
    assert @favorite_folder.has_favable?(@submission)
  end

  test "add favable should not allow duplicates" do
    @profile = profiles(:raccoon_profile_1)
    @submission = submissions(:dragon_image_1)
    @profile.favorite_folder.add_favable(@submission)
    assert_no_difference 'Favorite.count' do
      @profile.favorite_folder.add_favable(@submission)
    end
  end

  test "has favable" do
    @submission = submissions(:dragon_image_1)
    @favorite_folder = favorite_folders(:raccoon_raccoons_folder)
    @favorite_folder.add_favable(@submission)
    assert @favorite_folder.has_favable?(@submission),
      "favable was not found in the folder"
  end
end
