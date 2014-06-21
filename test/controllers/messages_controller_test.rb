require 'test_helper'

class MessagesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @user = @dragon.user
    @profile = @sender = @dragon
    @recipient = @raccoon
  end

  test "index" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:messages)
  end

  test "index should not work for logged out users" do
    get :index, profile_id: @profile
    assert_response :unauthorized
    assert_not assigns(:messages)
  end

  test "index should not work for other profiles" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index, profile_id: @profile
    assert_response :forbidden
    assert_not assigns(:messages)
  end

  test "index should not show deleted messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:deleted, true)
    get :index, profile_id: @profile
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert_not assigns(:messages).include?(@message)
  end

  test "index should not show archived messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:archived, true)
    get :index, profile_id: @profile
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert_not assigns(:messages).include?(@message)
  end

  test "index for mailbox deleted should show deleted messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:deleted, true)
    get :index, profile_id: @profile, mailbox: 'deleted'
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert assigns(:messages).include?(@message)
  end

  test "index for mailbox deleted should not show undeleted messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:deleted, true)
    get :index, profile_id: @profile, mailbox: 'deleted'
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert_not assigns(:messages).include?(messages(:raccoon_to_dragon_2))
  end

  test "index for mailbox archived should show archived messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:archived, true)
    get :index, profile_id: @profile, mailbox: 'archived'
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert assigns(:messages).include?(@message)
  end

  test "index for mailbox archived should not show unarchived messages" do
    login_user
    set_profile
    @message = messages(:raccoon_to_dragon_1)
    @message.update_attribute(:archived, true)
    get :index, profile_id: @profile, mailbox: 'archived'
    assert_response :success
    assert_equal 1, assigns(:messages).size
    assert_not assigns(:messages).include?(messages(:raccoon_to_dragon_2))
  end

  test "show" do
    login_user
    set_profile
    message = create_message(@raccoon, @dragon)
    get :show, profile_id: @dragon, id: message
    assert_response :success
    assert assigns(:message)
  end

  test "show should not show someone elses message" do
    login_user
    set_profile
    message = create_message(@raccoon, @lion)
    get :show, profile_id: @dragon, id: message
    assert_response :not_found
  end

  test "new" do
    login_user
    set_profile
    get :new, profile_id: @dragon
    assert_response :success
    assert assigns(:message)
  end

  test "create" do
    login_user
    set_profile
    assert_difference 'Message.count' do
      post :create,
           profile_id: @profile,
           recipient_id: @recipient.id,
           subject: 'Hi',
           body: 'Hey there'
    end
    assert_response :created
    message = assigns(:message)
    assert_equal @profile, message.sender
    assert_equal @recipient, message.recipient
    assert message.unread?
  end

  test "destroy" do
    login_user
    set_profile
    message = create_message(@raccoon, @dragon)
    assert_difference 'Message.count', -1 do
      delete :destroy, profile_id: @dragon, id: message
    end
    assert_response :no_content
  end

  test "mark read" do
    login_user
    set_profile
    message = create_message(@raccoon, @dragon)
    assert message.unread
    patch :mark_read, profile_id: @dragon, id: message
    assert_response :no_content
    message.reload
    assert_not message.unread
  end

  test "bulk delete" do
    login_user
    set_profile
    @message1 = messages(:raccoon_to_dragon_1)
    @message2 = messages(:raccoon_to_dragon_2)
    delete :bulk_delete, profile_id: @dragon, ids: [@message1.id, @message2.id]
    assert_response :no_content
    @message1.reload
    @message2.reload
    assert @message1.deleted
    assert @message2.deleted
  end

  test "bulk archive" do
    login_user
    set_profile
    @message1 = messages(:raccoon_to_dragon_1)
    @message2 = messages(:raccoon_to_dragon_2)
    patch :bulk_archive, profile_id: @dragon, ids: [@message1.id, @message2.id]
    assert_response :no_content
    @message1.reload
    @message2.reload
    assert @message1.archived
    assert @message2.archived
  end

  test "bulk mark read" do
    login_user
    set_profile
    @message1 = messages(:raccoon_to_dragon_1)
    @message2 = messages(:raccoon_to_dragon_2)
    patch :bulk_mark_read, profile_id: @dragon, ids: [@message1.id, @message2.id]
    assert_response :no_content
    @message1.reload
    @message2.reload
    assert_not @message1.unread
    assert_not @message2.unread
  end
end
