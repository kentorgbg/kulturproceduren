# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render file: "#{Rails.root}/public/404", layout: false, status: :not_found, formats: [ :html ]
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  #prepend_before_filter :maintenance_redirect
  before_filter :goto_redirect

  protected

  #def maintenance_redirect
  #  url_root = ActionController::Base.relative_url_root || ""
  #  redirect_to(url_root + "/maintenance.html", status: :found)
  #end

  #Redirect for goto queries
  def goto_redirect
    if params[:goto]
      if ActionController::Base.relative_url_root && !params[:goto].start_with?(ActionController::Base.relative_url_root)
        redirect_to ActionController::Base.relative_url_root + params[:goto]
      else
        redirect_to params[:goto]
      end
    end
  end

  # Method for getting the SQL sort order from paging parameters
  def sort_order(default)
    "#{sort_column_from_param(params[:c] || default)} #{params[:d] == 'down' ? 'DESC' : 'ASC'}"
  end
  helper_method :sort_order

  # Called from <tt>sort_order()</tt> to get the sort column in the database
  # based on the incoming parameter.
  #
  # This method should be overriden in subclasses using paging. The method
  # should implement functionality filtering the incoming parameter making it
  # impossible to sort by a column that is not allowed.
  def sort_column_from_param(p)
    p
  end

  # Ensures that the user is authenticated, used as a <tt>before_filter</tt>
  def authenticate
    unless session[:current_user_id]

      session[:return_to] = request.parameters
      flash[:error] = "Du har inte behörighet att komma åt sidan. Var god logga in."
      redirect_to controller: "login"
      return false
    end
  end

  # Ensures that the user is an administrator, used as a <tt>before_filter</tt>
  def require_admin
    unless current_user.has_role? :admin
      flash[:notice] = "Du har inte behörighet att komma åt sidan."
      redirect_to action: "index"
      return false
    end
  end


  # Helper method for checking whether the current user is logged in or not.
  def user_online?
    !session[:current_user_id].nil?
  end
  helper_method :user_online?

  # Accessor method for getting the current user.
  def current_user
    @current_user ||= User.find(session[:current_user_id]) if user_online?
  end
  helper_method :current_user


  # Cache key builder for the occasion list in the <tt>event/show</tt> view.
  def occasion_list_cache_key(event)
    online = user_online?
    user = online ? current_user : nil
    online_prefix = online ? "" : "not_"
    bookable_prefix = online && user.can_book? ? "" : "not_"
    administratable_prefix = online && user.can_administrate?(event.culture_provider) ? "" : "not_"
    reportable_prefix = online && (user.has_role?(:admin) || user.has_role?(:host)) ? "" : "not_"

    "events/show/#{event.id}/occasion_list/#{online_prefix}online/#{bookable_prefix}bookable/#{administratable_prefix}administratable/#{reportable_prefix}reportable"
  end
  helper_method :occasion_list_cache_key


  def send_csv(filename, csv)
    csv = replace_emoji(csv.gsub(/\n/,"\r\n"), '?').encode("windows-1252")
    send_data(
      csv,
      filename: filename,
      type: "text/csv; charset=windows-1252; header=present",
      disposition: "inline"
    )
  end

  private

  def replace_emoji ( str , replacement)
    # To replace with nothing use ''

    str = str.force_encoding('utf-8').encode
    clean_text = ""

    # emoticons 1F601 - 1F64F
    regex = /[\u{1f600}-\u{1f64f}]/
    clean_text = str.gsub regex, replacement

    # #dingbats 2702 - 27B0
    # regex = /[\u{2702}-\u{27b0}]/
    # clean_text = clean_text.gsub regex, replacement
    #
    # # transport/map symbols
    # regex = /[\u{1f680}-\u{1f6ff}]/
    # clean_text = clean_text.gsub regex, replacement
    #
    # # enclosed chars 24C2 - 1F251
    # regex = /[\u{24C2}-\u{1F251}]/
    # clean_text = clean_text.gsub regex, replacement
    #
    # # symbols & pics
    # regex = /[\u{1f300}-\u{1f5ff}]/
    # clean_text = clean_text.gsub regex, replacement
  end

end
