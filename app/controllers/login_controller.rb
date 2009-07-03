class LoginController < ApplicationController

  layout "standard"
  
  def index
  end

  def login
    if user_online?
      redirect_to :action => "index"
    end
    
    u = User.authenticate params[:user][:username], params[:user][:password]

    if u.nil?
      flash[:warning] = "Felaktigt användarnamn/lösenord"
      render :action => "index"
    else
      flash[:notice] = "Du är nu inloggad som #{CGI.escapeHTML(u.username)}"
      session[:current_user_id] = u.id
      
      if session[:return_to]
        redirect_to session[:return_to]
        session[:return_to] = nil
      else
        redirect_to "/"
      end
    end
  end

  def logout
    if user_online?
      session[:current_user_id] = nil
      flash[:notice] = "Du är nu utloggad."
      redirect_to "/"
    else
      redirect_to :action => "index"
    end
  end

end
