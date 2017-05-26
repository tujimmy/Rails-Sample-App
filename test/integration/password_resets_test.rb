require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  def setup
    # reset delivered mail to 0
    ActionMailer::Base.deliveries.clear
    @user = users(:jimmy)
  end
  
  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # invalid email
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # password reset form
    user = assigns(:user)
    # wrong email
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    # activate user
    user.toggle!(:activated)
    # right email, wrong token
    get edit_password_reset_path("wrong token", email: user.email)
    assert_redirected_to root_url
    # right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # invalid password & confirmation
    patch password_reset_path(user.reset_token),
      params:   { email: user.email,
                  user: { password: "foobar",
                          password_confirmation: "barfoo" } }
    assert_select 'div#error_explanation'
    # empty password
    patch password_reset_path(user.reset_token),
      params:   { email: user.email,
                  user: { password: "",
                          password_confirmation: "" } }
    assert_select 'div#error_explanation'
    # valid password & confirmation
    patch password_reset_path(user.reset_token),
      params:   { email: user.email,
                  user: { password: "password",
                          password_confirmation: "password" } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    assert_nil user.reload.reset_digest
  end
  
  test "expired token" do
    get new_password_reset_path
    post password_resets_path,
        params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
        params: { email: @user.email,
                  user: { password: "foobar",
                          password_confirmation: "foobar" } }
    assert_response :redirect
    follow_redirect!  
    assert_match(/expired/i, response.body)
  end
  
end
