module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end
  
  def current_user?(user)
    user == current_user
  end
  
  def current_user 
    # User object is true, the call to find_by only gets executed
    # if current_user hasn't yet been assigned
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: session[:user_id])
    elsif (user_id = cookies.signed[:user_id])
      # raise # The tests still pass, so this branch is currently untested.
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end
  
  def logged_in?
    !current_user.nil?
  end
  
  # forgets a persistent session 9.12
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
  
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  # Redirects to stored location or to the default 10.30
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
  
  # Stores the URL trying to be accessed 10.3
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
  
end
