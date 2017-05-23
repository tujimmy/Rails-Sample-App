require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:jimmy)
  end
  
  test "unsuccessful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: { name: "",
                                              email: "foo@invalid",
                                              password: "foo",
                                              password_confirmation: "bar" } }
    assert_template 'users/edit'    
    assert_select "div.alert", "The form contains 4 errors."
  end
  
  test "successful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template "users/edit"
    name = "Foo Bar"
    email = "foo@email.com"
    patch user_path(@user), params: { user: { name: name,
                                             email: email,
                                             password: "",
                                             password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end
  
  test "successful edit with friendly forwarding" do
    # issue first page request
    get edit_user_path(@user)
    # user is not logged in, so requested URL is stored in session[:forwarding_url]
    log_in_as(@user)
    
    # user is logged in and should be redirected to
    # session[:forwarding_url]
    assert_redirected_to edit_user_url(@user)
    assert_nil session[:forwarding_url]
    
    name = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { name: name,
                                              email: email,
                                              password: "",
                                              password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
    
    # on subsequent login attempts, user should be redirected to the 
    # profile page
    assert_nil session[:forwarding_url]
    log_in_as(@user)
    assert_redirected_to user_url(@user)

                                            
  end
  

  

  
end
