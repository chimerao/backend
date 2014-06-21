require 'test_helper'

class StreamsControllerTest < ActionController::TestCase
  
  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
  end

  test "index" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
  end

  test "index should show permenant streams" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:streams).include?(streams(:dragon_submissions_stream))
  end

  test "index should show others permanent streams" do
    login_user
    set_profile
    get :index, profile_id: @lion
    assert_response :success
    assert assigns(:streams).include?(streams(:lion_submissions_stream))
  end

  test "index should not show others non-permanent non-public streams" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:streams).include?(streams(:dragon_private_fatty_stream))
  end

  test "index should show private streams for the same profile" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:streams).include?(streams(:dragon_private_fatty_stream))
  end

  test "show" do
    login_user(@lion.user)
    set_profile(@lion)
    get :show,
        profile_id: @profile,
        id: streams(:dragon_public_dragon_stream)
    assert_response :success
  end

  test "show render if stream has items" do
    login_user
    set_profile
    stream = @profile.streams.create(name: 'test', rules: 'journals:all')
    get :show, profile_id: @profile, id: stream
    assert_response :success
  end

  test "show should succeed if stream has no items" do
    login_user
    set_profile
    stream = @profile.streams.create(name: 'test stream', rules: 'submissions:fjadofjio')
    get :show, profile_id: @profile, id: stream
    assert_response :success
  end

  test "show should succeed for another profile's public stream" do
    login_user(@lion.user)
    set_profile(@lion)
    get :show, profile_id: @profile, id: streams(:dragon_public_dragon_stream)
    assert_response :success
  end

  test "show should not get another profile's private stream" do
    login_user(@lion.user)
    set_profile(@lion)
    get :show, profile_id: @profile, id: streams(:dragon_private_fatty_stream)
    assert_response :not_found
  end

  test "show should not get another profile's permanent stream" do
    login_user(@lion.user)
    set_profile(@lion)
    get :show, profile_id: @profile, id: streams(:dragon_submissions_stream)
    assert_response :not_found
  end

  test "show should not get your own individual permanent streams" do
    login_user
    set_profile
    get :show, profile_id: @profile, id: streams(:dragon_submissions_stream)
    assert_response :not_found
  end

  test "new" do
    login_user
    set_profile
    get :new, profile_id: @profile
    assert_response :success
  end

  test "create tags" do
    login_user
    set_profile
    assert_difference 'Stream.count' do
      post :create,
           profile_id: @profile,
           id: @stream,
           name: 'Hippos',
           tags: ['hippos', 'fat']
    end
    assert_response :created
    stream = assigns(:stream)
    assert_equal 'Hippos', stream.name
    assert stream.rules.include?('tags:hippos,fat')
  end

  test "create tags for journals" do
    login_user
    set_profile
    assert_difference 'Stream.count' do
      post :create,
           profile_id: @profile,
           id: @stream,
           name: 'Hippos',
           tags: ['hippos', 'fat'],
           include_journals: true
    end
    assert_response :created
    stream = assigns(:stream)
    assert stream.include_journals?
  end

  test "create tags for submissions" do
    login_user
    set_profile
    assert_difference 'Stream.count' do
      post :create,
           profile_id: @profile,
           id: @stream,
           name: 'Hippos',
           tags: ['hippos', 'fat'],
           include_submissions: true
    end
    assert_response :created
    stream = assigns(:stream)
    assert stream.include_submissions?
  end

  test "create tags for journals and submissions" do
    login_user
    set_profile
    assert_difference 'Stream.count' do
      post :create,
           profile_id: @profile,
           id: @stream,
           name: 'Hippos',
           tags: ['hippos', 'fat'],
           include_journals: true,
           include_submissions: true
    end
    assert_response :created
    stream = assigns(:stream)
    assert stream.include_submissions?
    assert stream.include_journals?
  end

  test "update" do
    login_user
    set_profile
    @stream = streams(:dragon_public_dragon_stream)
    assert_not_equal 'No Dragons Here', @stream.name
    patch :update,
          profile_id: @profile,
          id: @stream,
          name: 'No Dragons Here'
    assert_response :no_content
    @stream.reload
    assert_equal 'No Dragons Here', @stream.name
  end

  test "update should patch stream" do
    @stream = streams(:dragon_public_dragon_stream)
    assert @stream.is_public
    login_user
    set_profile
    patch :update,
          profile_id: @profile,
          id: @stream,
          is_public: false
    @stream.reload
    assert_not @stream.is_public
    assert_response :no_content
  end

  test "patch update should fail if stream is owned by another profile" do
    @stream = streams(:dragon_public_dragon_stream)
    assert @stream.is_public
    login_user(users(:lion))
    set_profile(@lion)
    patch :update,
          profile_id: @profile,
          id: @stream,
          is_public: false
    @stream.reload
    assert @stream.is_public
    assert_redirected_to dash_path
  end

  test "destroy" do
    login_user
    set_profile
    @stream = streams(:dragon_public_dragon_stream)
    assert_difference 'Stream.count', -1 do
      delete :destroy, profile_id: @profile, id: @stream
    end
    assert_response :no_content
  end

  test "destroy should fail if stream is owned by another profile" do
    login_user(@lion.user)
    set_profile(@lion)
    assert_no_difference 'Stream.count' do
      delete :destroy, profile_id: @profile, id: streams(:dragon_public_dragon_stream)
    end
  end

  test "destroy should fail if stream is permanent" do
    login_user
    set_profile
    assert_no_difference 'Stream.count' do
      delete :destroy, profile_id: @profile, id: streams(:dragon_submissions_stream)
    end
  end

#  test "should be able to view a public stream while logged out" do
#    get :show, :profile_id => @profile, :id => streams(:dragon_public_dragon_stream)
#    assert_response :success
#  end

#  test "create submission search stream" do
#    login_user
#    set_profile
#    assert_difference 'Stream.count' do
#      post :create,
#           :profile_id => @profile,
#           :stream => { :name => 'New Stream' },
#           :tags => 'yellow,dragon'
#    end
#  end

  test "stream" do
    login_user
    set_profile
    get :stream, profile_id: @profile
    assert_response :success
    assert_equal 5, assigns(:tidbits).size
  end

  test "stream should not allow access to other profiles" do
    login_user
    set_profile
    get :stream, profile_id: @raccoon
    assert_response :forbidden
  end

  test "stream pagination" do
    login_user
    set_profile
    get :stream, profile_id: @profile, per_page: 2
    assert_response :success
    assert_equal 2, assigns(:tidbits).size
    assert_not assigns(:tidbits).include?(tidbits(:tidbit_for_dragon_4))

    get :stream, profile_id: @profile, per_page: 2, page: 2
    assert_response :success
    assert_equal 2, assigns(:tidbits).size
    assert assigns(:tidbits).include?(tidbits(:tidbit_for_dragon_4))
  end

  test "customize should add individual streams" do
    login_user
    set_profile
    @stream1 = streams(:lion_submissions_stream)
    @stream2 = streams(:lion_journals_stream)
    @stream3 = streams(:lion_comments_stream)
    patch :customize, profile_id: @lion, stream_ids: [@stream1.id, @stream3.id]
    assert_response :no_content
    assert @profile.following_stream?(@stream1)
    assert @profile.following_stream?(@stream3)
    assert_not @profile.following_stream?(@stream2)
  end

  test "customize should remove individual streams" do
    login_user
    set_profile
    @profile.follow_profile(@lion)
    @stream1 = streams(:lion_submissions_stream)
    @stream2 = streams(:lion_journals_stream)
    @stream3 = streams(:lion_comments_stream)
    patch :customize, profile_id: @lion, stream_ids: [@stream1.id, @stream3.id]
    assert_response :no_content
    assert @profile.following_stream?(@stream1)
    assert @profile.following_stream?(@stream3)
    assert_not @profile.following_stream?(@stream2)
  end

  test "customize should not add private streams" do
    login_user(@raccoon.user)
    set_profile(@raccoon)
    @stream1 = streams(:dragon_private_fatty_stream)
    patch :customize, profile_id: @profile, stream_ids: [@stream1.id]
    assert_response :no_content
    assert_not @raccoon.following_stream?(@stream1),
      "followed a private stream without access"
  end

  test "customize should not add some other profiles streams" do
    login_user(@raccoon.user)
    set_profile(@raccoon)
    @stream1 = streams(:lion_submissions_stream)
    patch :customize, profile_id: @profile, stream_ids: [@stream1.id]
    assert_response :no_content
    assert_not @raccoon.following_stream?(@stream1),
      "followed another profile's stream"
  end
end
