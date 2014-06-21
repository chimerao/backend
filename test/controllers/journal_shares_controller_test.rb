require 'test_helper'

class JournalSharesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @journal = journals(:donkey_journal_1)
  end

  test "share journal" do
    login_user
    set_profile
    assert_difference 'Share.count' do
      post :create, id: @journal
    end
    assert_response :no_content
  end

  test "should not be able to share the same journal twice" do
    @profile.shares.create(shareable: @journal)
    login_user
    set_profile
    assert_no_difference 'Share.count' do
      post :create, id: @journal
    end
    assert_response :unprocessable_entity
  end

  test "unshare journal" do
    @profile.shares.create(shareable: @journal)
    login_user
    set_profile
    assert_difference 'Share.count', -1 do
      delete :destroy, id: @journal
    end
    assert_response :no_content
  end

  test "cannot share while logged out" do
    assert_no_difference 'Share.count' do
      post :create, id: @journal
    end
  end
end