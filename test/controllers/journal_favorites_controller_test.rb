require 'test_helper'

class JournalFavoritesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @journal = journals(:dragon_journal_1)
  end

  test "fave journal" do
    login_user
    set_profile
    assert_difference 'Favorite.count' do
      post :create, id: @journal
    end
    assert_response :no_content
  end

  test "unfave journal" do
    @profile.favorites.create(favable: @journal)
    login_user
    set_profile
    assert_difference 'Favorite.count', -1 do
      delete :destroy, id: @journal
    end
    assert_response :no_content
  end

end
