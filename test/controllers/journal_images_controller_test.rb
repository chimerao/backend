require 'test_helper'

class JournalImagesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @dragon = profiles(:dragon_profile_1)
    @profile = @dragon
    @user = @profile.user
    @journal = journals(:dragon_journal_1)
    # Cleanup if necessary
    tmp_file_path = File.join(Rails.root, 'tmp', 'FLCL.jpg')
    FileUtils.rm(tmp_file_path) if File.exists?(tmp_file_path)
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'FLCL.jpg')
    login_user
    set_profile
  end

  test "index" do
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    @journal_image = @journal.journal_images.create(image: image, profile: @profile)
    get :index,
        profile_id: @profile,
        journal_id: @journal
    assert_response :success
    assert assigns(:journal_images)
  end

  test "index should fail for other profiles" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index,
        profile_id: @profile,
        journal_id: @journal
    assert_response :forbidden
  end

  test "create" do
    @request.headers['Content-Type'] = 'application/octet-stream'
    @request.headers['Content-Disposition'] = 'inline; filename="FLCL.jpg"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    assert_difference 'JournalImage.count' do
      post :create,
           profile_id: @profile,
           journal_id: @journal
    end
    assert_response :created
    image = assigns(:journal_image)
    assert image
    assert_equal 'FLCL.jpg', image.image_file_name
    assert_equal 'image/jpeg', image.image_content_type
  end

  test "delete" do
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    @journal_image = @journal.journal_images.create(image: image, profile: @profile)
    assert_difference 'JournalImage.count', -1 do
      delete :destroy,
             profile_id: @profile,
             journal_id: @journal,
             id: @journal_image
    end
    assert_response :no_content
  end

  test "delete should fail for other profiles" do
    login_user(@lion.user)
    set_profile(@lion)
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    @journal_image = @journal.journal_images.create(image: image, profile: @profile)
    assert_no_difference 'JournalImage.count' do
      delete :destroy,
             profile_id: @profile,
             journal_id: @journal,
             id: @journal_image
    end
    assert_response :forbidden
  end
end