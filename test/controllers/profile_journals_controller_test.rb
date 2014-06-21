require 'test_helper'

class ProfileJournalsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @journal = journals(:dragon_journal_1)
    @private_journal = journals(:dragon_friend_journal_1)
    @unpublished_journal = journals(:dragon_unpublished_journal_1)
  end

  test "index" do
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:journals)
  end

  test "index should show to logged out users" do
    get :index, profile_id: @profile
    assert_response :success
  end

  test "index should include a profile" do
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:profile), "@profile doesn't exist in profile journals path"
  end

  test "index should not show private journals to logged out users" do
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:journals).include?(@private_journal),
               "logged out user saw a private journal in a collection"
  end

  test "index should not show private journals to other profiles" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:journals).include?(@private_journal),
               "a profile saw a private journal in a collection they shouldn't have"
  end

  test "index should show private journals to other profiles on the same filter" do
    login_user(@lion.user)
    profile = @lion
    set_profile(profile)
    filters(:dragon_friend_filter).profiles << profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:journals).include?(@private_journal),
           "a profile did not see private journal they were filtered for"
  end

  test "index should show private journals to journal owner" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert assigns(:journals).include?(@private_journal),
           "owner did not see their own private journal"
    assert_equal 2, assigns(:journals).size
  end

  test "index should not include unpublished journals" do
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:journals).include?(@unpublished_journal),
               "an unpublished journal was shown"
  end

  # Pagination

  test "index pagination" do
    login_user
    set_profile
    get :index,
        profile_id: @profile,
        per_page: 1,
        page: 1
    assert_response :success
    assert_equal 1, assigns(:journals).size
    assert_equal @private_journal, assigns(:journals).first

    get :index,
        profile_id: @profile,
        per_page: 1,
        page: 2
    assert_response :success
    assert_equal @journal, assigns(:journals).first
  end

  test "new" do
    login_user
    set_profile
    get :new, profile_id: @profile
    assert_response :success
    assert assigns(:journal)
  end

  test "create" do
    login_user
    set_profile
    assert_difference 'Journal.count' do
      post :create,
           profile_id: @profile,
           title: 'A new journal',
           body: 'With new thoughts.'
    end
    assert_response :created
    assert assigns(:journal)
  end

  test "create should convert HTML body input to markdown" do
    login_user
    set_profile
    post :create,
         profile_id: @profile,
         title: 'A journal about dragons',
         body: "<p>Let me tell you about toony dragons. There <i>aren't enough</i> of them!</p>"
    assert_response :created
    journal = assigns(:journal)
    assert !journal.body.match(/<[^>]*>/),
      "the journal body contains HTML"
  end

  test "create should not alter markdown body input" do
    login_user
    set_profile
    body_text = "Let me tell you about toony dragons. There _aren't enough_ of them!"
    post :create,
         profile_id: @profile,
         title: 'A journal about dragons',
         body: body_text
    assert_response :created
    journal = assigns(:journal)
    assert_equal body_text, journal.body,
      "the journal body markdown input was changed when it shouldn't have been"
  end

  test "create should clean up messy whitespace in HTML input" do
    login_user
    set_profile
    input_text = "<p>There <strong>needs </strong> to be <em>more </em>of them!<p>"
    output_text = "There **needs** to be _more_ of them!\n\n"
    post :create,
         profile_id: @profile,
         title: 'About toony dragons',
         body: input_text
    assert_response :created
    journal = assigns(:journal)
    assert_equal output_text, journal.body,
      "messy HTML whitespace was left in"
  end

  test "create should send a tidbit if published as well" do
    login_user
    set_profile
    @raccoon.follow_profile(@dragon)
    assert_difference 'Tidbit.count' do
      post :create,
           profile_id: @profile,
           title: 'A new journal',
           body: 'With new thoughts.',
           published_at: Time.now
    end
    assert_response :created
    assert assigns(:journal)
  end

  test "publish should publish a journal" do
    login_user
    set_profile
    patch :publish, profile_id: @profile, id: @unpublished_journal
    @unpublished_journal.reload
    assert @unpublished_journal.is_published?
    assert_response :no_content
  end

  test "publish should not work if title is absent" do
    login_user
    set_profile
    @unpublished_journal.title = nil
    @unpublished_journal.save!
    patch :publish, profile_id: @profile, id: @unpublished_journal
    @unpublished_journal.reload
    assert_not @unpublished_journal.is_published?
  end

  test "publish should not work for the journal of another profile" do
    login_user(@lion.user)
    set_profile(@lion)
    patch :publish, profile_id: @profile, id: @unpublished_journal
    @unpublished_journal.reload
    assert_not @unpublished_journal.is_published?
  end

  test "update" do
    login_user
    set_profile
    assert_not_equal 'derp', @journal.title
    patch :update,
          profile_id: @profile,
          id: @journal,
          title: 'derp'
    assert_response :no_content
    @journal.reload
    assert_equal 'derp', @journal.title
  end

  test "update should not work for the journal of another profile" do
    login_user(@lion.user)
    set_profile(@lion)
    get :update, profile_id: @profile, id: @journal, journal: { title: 'Changed it!' }
    @journal.reload
    assert_not_equal 'Changed it!', @journal.title
  end

  test "update should accept multiple filters" do
    login_user
    set_profile
    filter1 = filters(:dragon_friend_filter)
    filter2 = filters(:dragon_fatty_filter)
    patch :update,
          profile_id: @profile,
          id: @unpublished_journal,
          filter_ids: [filter1.id, filter2.id]
    assert assigns(:journal).filters.include?(filter1),
      "a filter was not added to journal"
    assert assigns(:journal).filters.include?(filter2),
      "a filter was not added to journal"
  end

  test "update should convert HTML body input to markdown" do
    login_user
    set_profile
    patch :update,
          id: @journal,
          profile_id: @profile,
          title: 'A journal about dragons',
          body: "<p>Let me tell you about toony dragons. There <i>aren't enough</i> of them!</p>"
    assert_response :no_content
    journal = assigns(:journal)
    assert !journal.body.match(/<[^>]*>/),
      "the journal body contains HTML"
  end

  test "update should not alter markdown body input" do
    login_user
    set_profile
    body_text = "Let me tell you about toony dragons. There _aren't enough_ of them!"
    patch :update,
          id: @journal,
          profile_id: @profile,
          title: 'A journal about dragons',
          body: body_text
    journal = assigns(:journal)
    assert_response :no_content
    assert_equal body_text, journal.body,
      "the journal body markdown input was changed when it shouldn't have been"
  end

  test "series should create a new form in a series" do
    login_user
    set_profile
    get :series,
        profile_id: @profile,
        id: @journal
    assert_response :success
    assert_equal @journal, assigns(:journal).previous_journal,
      "journal was not added to the new one in series"
  end

  test "update should not set a previous journal that the current profile does not own" do
    login_user
    set_profile
    unowned_journal = journals(:donkey_journal_1)
    patch :update,
          profile_id: @profile,
          id: @journal,
          title: 'A new journal',
          body: 'Adding to one I do not own',
          journal_id: unowned_journal.id
    assert_not_equal unowned_journal, @journal.next_journal,
      "unowned journal was set next"
    assert_not assigns(:journal).valid?,
      "journal should not be valid"
  end

  test "update should update tag list" do
    login_user
    set_profile
    assert_not @journal.tag_list.include?('herp')
    assert_not @journal.tag_list.include?('derp')
    patch :update,
          profile_id: @profile,
          id: @journal,
          tags: [
            'herp',
            'derp'
          ]
    @journal.reload
    assert @journal.tag_list.include?('herp'),
      "tag was not added"
    assert @journal.tag_list.include?('derp'),
      "tag was not added"
  end

  test "destroy" do
    login_user
    set_profile
    assert_difference 'Journal.count', -1 do
      delete :destroy, profile_id: @profile, id: @journal
    end
    assert_response :no_content
  end

  test "unpublished" do
    login_user
    set_profile
    get :unpublished, profile_id: @profile
    assert_response :success
    assert assigns(:journals)
  end
end
