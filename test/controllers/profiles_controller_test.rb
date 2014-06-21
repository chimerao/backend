require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @private_submission = submissions(:dragon_friend_submission_1)
    @private_journal = journals(:dragon_friend_journal_1)
  end

  test "index" do
    login_user
    set_profile
    get :index
    assert_response :success
    assert assigns(:profiles)
    assert assigns(:profiles).include?(@profile)
  end

  test "show" do
    login_user
    set_profile
    get :show, id: @profile
    assert_response :success
    assert assigns(:profile)
    assert assigns(:other_profiles)
    assert assigns(:public_filters)
    assert assigns(:relation_tags)
    assert assigns(:following_count)
    assert assigns(:followers_count)
  end

  test "show should work for logged out users" do
    get :show, id: @profile
    assert_response :success
  end

  test "profile home with site identifier" do
    get :show, site_identifier: @profile.site_identifier
    assert_response :success
  end

  test "new" do
    login_user
    get :new
    assert_response :success
    assert assigns(:profile)
  end

  test "new should not require a user to have a profile" do
    @user = users(:profileless)
    login_user
    get :new
    assert_response :success
  end

  test "create" do
    login_user
    post :create,
         profile: {
           name: 'Hippo',
           site_identifier: 'Hippo'
         }
    assert_response :created
    assert assigns(:profile)
  end

  test "create should not require a user to have a profile" do
    @user = users(:profileless)
    login_user
    assert_difference 'Profile.count' do
      post :create,
           profile: {
             name: 'Frog',
             site_identifier: 'Frog'
           }
    end
    @user.reload
    assert_equal 'Frog', @user.default_profile.name
    assert_response :created
  end

  test "switch to another profile" do
    login_user
    set_profile
    assert_equal @user.default_profile, @profile
    post :switch, id: @donkey
    assert_equal @user.default_profile, @donkey
  end

  test "cannot switch to another user's profile" do
    login_user
    set_profile
    assert_equal @user.default_profile, @profile
    post :switch, id: @lion
    assert_equal @user.default_profile, @profile
  end

  test "follow" do
    login_user
    set_profile
    assert_not @profile.following_profile?(@lion)
    post :follow, id: @lion
    assert_response :no_content
    @profile.reload
    assert @profile.following_profile?(@lion)
  end

  test "unfollow" do
    login_user
    set_profile
    @profile.follow_profile(@lion)
    assert @profile.following_profile?(@lion)
    delete :unfollow, id: @lion
    assert_response :no_content
    @profile.reload
    assert_not @profile.following_profile?(@lion)
  end

  test "following a profile should follow all default streams" do
    login_user
    set_profile
    assert_difference 'Favorite.count', 5 do
      post :follow, id: @lion
    end

    assert_response :no_content
  end

  test "unfollowing a profile should unfollow all streams" do
    login_user
    set_profile
    @profile.follow_profile(@lion)
    assert_difference 'Favorite.count', -5 do
      delete :unfollow, id: @lion
    end
    assert_response :no_content
  end

  test "update bio" do
    login_user
    set_profile
    assert_nil @profile.bio
    patch :update, id: @profile, profile: {
      bio: 'Just a derpy dragon.'
    }
    @profile.reload
    assert_not_nil @profile.bio
    assert_equal 'Just a derpy dragon.', @profile.bio
  end

  test "update location" do
    login_user
    set_profile
    assert_nil @profile.location
    patch :update, id: @profile, profile: {
      location: 'Shores of Honalee'
    }
    @profile.reload
    assert_not_nil @profile.location
    assert_equal 'Shores of Honalee', @profile.location
  end

  test "update homepage" do
    login_user
    set_profile
    assert_nil @profile.homepage
    patch :update, id: @profile, profile: {
      homepage: 'http://magicdragon.com'
    }
    @profile.reload
    assert_not_nil @profile.homepage
    assert_equal 'http://magicdragon.com', @profile.homepage
  end

  def setup_banner_image
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chimera-240.jpg')
    tmp_file_path = File.join(Rails.root, 'tmp', 'Chimera-240.jpg')
    FileUtils.rm(tmp_file_path) if File.exists?(tmp_file_path) # Cleanup if necessary
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'image/jpeg'
    @request.headers['Content-Disposition'] = 'inline; filename="Chimera-240.jpg"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
  end

  test "banner" do
    login_user
    set_profile
    assert_nil @profile.banner_image.path
    setup_banner_image

    post :banner, profile_id: @profile
    assert_response :success

    @profile.reload
    assert_not_nil @profile.banner_image.path
  end

  test "banner destroy" do
    login_user
    set_profile
    setup_banner_image
    post :banner, profile_id: @profile
    @profile.reload
    assert_not_nil @profile.banner_image.path

    delete :banner, profile_id: @profile
    assert_response :no_content
    @profile.reload
    assert_nil @profile.banner_image.path
  end

  test "json show site identifier" do
    get :show, site_identifier: @profile.site_identifier
    assert_response :success
    assert_equal @profile, assigns(:profile)
  end

  test "json show should display if profile has no default user pic" do
    login_user
    @profile = @user.profiles.create(name: 'Hippo', site_identifier: 'Hippo')
    set_profile
    get :show, id: @profile
    assert_response :success
    assert assigns(:profile)
  end

  test "update site identifier" do
    login_user
    set_profile
    assert_not_equal 'CandyDragon', @profile.site_identifier
    patch :update,
          id: @profile,
          profile: {
            site_identifier: 'CandyDragon'
          }
    assert_response :no_content
    @profile.reload
    assert_equal 'CandyDragon', @profile.site_identifier
  end

  test "update site identifier cannot be blank" do
    login_user
    set_profile
    assert_equal 'Dragon', @profile.site_identifier
    patch :update,
          id: @profile,
          profile: {
            site_identifier: ''
          }
    @profile.reload
    assert_equal 'Dragon', @profile.site_identifier
  end

  test "update site identifier must be unique" do
    login_user
    set_profile
    assert_equal 'Dragon', @profile.site_identifier
    patch :update,
          id: @profile,
          profile: {
            site_identifier: 'Lion'
          }
    @profile.reload
    assert_equal 'Dragon', @profile.site_identifier
  end

  test "switch should return no content" do
    login_user
    set_profile
    post :switch, id: @donkey
    assert_response :no_content
  end

  test "switch to an unowned profile should return bad request" do
    login_user
    set_profile
    post :switch, id: @lion
    assert_response :bad_request
  end
end