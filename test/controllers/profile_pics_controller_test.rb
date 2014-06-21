require 'test_helper'

class ProfilePicsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @pic = profile_pics(:dragon_profile_pic_1)
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chimera-240.jpg')
  end

  test "index" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:profile_pics)
  end

  test "index should not allow another profile to view" do
    login_user(@raccoon.user)
    set_profile(@raccoon)
    get :index, profile_id: @profile
    assert_response :forbidden
  end

  test "show" do
    login_user
    set_profile
    get :show, profile_id: @profile, id: @pic
    assert_response :success
    assert assigns(:profile_pic)
  end

  def setup_raw_create
    tmp_file_path = File.join(Rails.root, 'tmp', 'Chimera-240.jpg')
    FileUtils.rm(tmp_file_path) if File.exists?(tmp_file_path) # Cleanup if necessary
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'image/jpeg'
    @request.headers['Content-Disposition'] = 'inline; filename="Chimera-240.jpg"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
  end

  test "raw create" do
    setup_raw_create
    login_user
    set_profile
    assert_difference 'ProfilePic.count' do
      post :create, profile_id: @profile
    end
    profile_pic = assigns(:profile_pic)
    profile_pic.reload
    assert_equal 'Chimera-240.jpg', profile_pic.image_file_name
    assert_equal 'image/jpeg', profile_pic.image_content_type
  end

  test "raw create should set profile pic default if it is the only one" do
    setup_raw_create
    @profile = @raccoon
    login_user(@profile.user)
    set_profile(@profile)
    assert_difference 'ProfilePic.count' do
      post :create, profile_id: @profile
    end
    assert assigns(:profile_pic).is_default,
      "profile pic was not set as default"
    @profile.reload
    assert_equal @profile.default_profile_pic, assigns(:profile_pic),
      "profile pic was not set as default for the profile"
  end

  test "destroy" do
    login_user
    set_profile
    assert_difference 'ProfilePic.count', -1 do
      delete :destroy, profile_id: @profile, id: @pic
    end
    assert_response :no_content
    assert assigns(:profile_pic)
  end

  test "destroy should not remove an unowned profile pic" do
    @profile = @raccoon
    login_user(@profile.user)
    set_profile(@profile)
    assert_no_difference 'ProfilePic.count' do
      assert_raises ActiveRecord::RecordNotFound do
        delete :destroy, profile_id: @profile, id: @pic
      end
    end
  end

  test "make default" do
    login_user
    set_profile
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    new_pic = ProfilePic.create!(profile: @profile, image: image)
    assert @pic.is_default?
    patch :make_default, profile_id: @profile, id: new_pic
    assert_response :no_content
    new_pic.reload
    @profile.reload
    @pic.reload
    assert new_pic.is_default?,
      "new pic was not set default"
    assert_not @pic.is_default?,
      "old default was not removed"
  end
end
