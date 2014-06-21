class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #
#  protect_from_forgery with: :exception

  before_filter :check_format

  # Part of the Sorcery gem. By default, require login for everything.
  # Make skip_before_filter exceptions in controllers.
  #
  before_filter :require_login

  # Also require profile for everything for logged in users except
  # the obvious initial setup actions.
  #
  before_filter :require_profile

  # Get all notifications for the profile.
  #
  before_filter :get_notifications

  # We do not want the app trying to parse and render HTML pages.
  # Just send the default layout and let the client app take over.
  #
  def check_format
    if request.accept.nil? or request.accept.match(/html/i)
      render inline: '', layout: 'application', type: :raw
      return false
    end
  end

  # Custom method (call specified in sorcery config) to login
  # a user based on a session token.
  # 
  def login_from_session_token
#    return User.find(1)
    if request.headers['Authorization']
      @token = request.headers['Authorization'].scan(/[^Token](.+)/i).flatten.first.strip
      return nil if @token.length != 64
      redis = Redis.new
      store = redis.get("session_token:#{@token}")
      return nil if store.nil?
      store = JSON.parse(store)
      user_id = store[0]
      hash = store[1]

      if hash == hash_from_token(@token)
        return User.find_by_id(user_id)
      else
        # This means a key was found in redis, but it didn't match.
        # Either the user's network address got switched, or someone
        # else tried to get in with their key. Might be best
        # to just delete the key from redis?
        return nil
      end
    else
      return nil
    end      
  end

  def hash_from_token(token)
    str = generate_unique_client_string
    ::Digest::MD5.hexdigest(token + str + Rails.application.secrets.secret_key_base)
  end

  def generate_unique_client_string
    ip = request.ip.split('.')[0,3].join('.')
    agent = request.user_agent
    lang = request.accept_language
    str = Base64.encode64([ip, agent, lang].join('^.^'))
  end

  # We need to require a profile for just about all actions on
  # the site, but ONLY IF a user is logged in. Don't want logged
  # out users also getting bumped.
  #
  def require_profile
    if current_user and not current_user.default_profile
      redirect_to new_profile_path and return false
    end
  end

  # Sets the Profile instance variable, mainly for controllers in
  # the /profiles path
  #
  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])
  end

  # This is to make sure that the current_profile visiting a restricted
  # @profile page gets redirected.
  #
  def check_profile
    if @profile != current_profile
      respond_to do |format|
        format.html { redirect_to dash_path }
        format.json { head :forbidden }
      end
      return false
    end
  end

  # Get notifications for the current Profile for display and alerts
  #
  def get_notifications
    @notifications = current_profile.notifications if current_profile
  end

  # For pages that use the Profile banner, set up all necessary variables
  # required by it, and also a @use_banner variable to use in views.
  #
  def set_banner
    @use_banner = true
    @relation_tags = @profile.relations_from(current_profile)
    @public_filters = @profile.filters.opt_in
    @other_profiles = @profile.user.profiles.find(@profile.exposed_profiles)
    @following_count = @profile.following_profiles_count
    @followers_count = @profile.followed_by_profiles_count
  end

  # When to include inline editor javascript/css in a page.
  #
  def use_inline_editor
    @use_inline_editor = true;
  end

  # Sets the Link header for use in making API responses more
  # like how REST is supposed to be.
  # http://2beards.net/2012/03/what-the-hell-is-a-hypermedia-api-and-why-should-i-care/
  #
  # links:: Hash of links, i.e. {relation: uri}
  #
  def set_hypermedia_links(links)
    headers['Link'] = links.collect { |rel, link|
      if link.is_a?(Array) # means method is included
        uri = "<#{link[0]}>; method=\"#{link[1]}\";"
      else
        uri = "<#{link}>;"
      end
      "#{uri} rel=\"#{rel}\""
    }.join(', ')
  end

  # Helper methods

  # Each user has a current profile they're set as.
  # Returns nil if there's no current_user.
  #
  helper_method :current_profile
  def current_profile
    current_user ? current_user.default_profile : nil
  end
  
  # return the correct thumbnail dimension
  #
  helper_method :thumbnail_size
  def thumbnail_size
#    if current_user
#      return current_user.preferred_thumbnail_size
#    else
      return Submission::DEFAULT_THUMBNAIL_SIZE
#    end
  end

  # Returns the URL for a Profile's ProfilePic, or default if none exists.
  # Options that can be passed in:
  # :size => The thumbnail size to be returned, defined in ProfilePic
  # :profile_pic => A specific ProfilePic, in objects where user can select. Can be nil.
  #
  helper_method :url_for_profile_pic
  def url_for_profile_pic(profile, options = {})
    options[:size] ||= 'pixels_128'
    profile_pic = options[:profile_pic] ? options[:profile_pic] : profile.default_profile_pic
    # Return the profile_pic url or the default based on the attachment config
    profile_pic ? profile_pic.image(options[:size]) : ProfilePic.new.image(options[:size])
  end

  # Sanitizes the tags for a few common methods of entering them, so they
  # get returned as a nice, cleaned up array.
  #
  def sanitize_tags(tag_string)
    tag_string ||= '' # handling of nil
    tag_string.gsub!('#', '')
    if tag_string.include?(',')
      tags = tag_string.split(',')
    else
      tags = tag_string.split(' ')
    end
    return tags.collect { |tag| tag.strip }
  end

  # This searches a string for tags predicated with a # and returns them all as an array.
  #
  def collect_tags_from_string(string)
    return string ? string.scan(/(?<=#)\w+/) : ''
  end

  protected

    # A convience method that sets the @page_title based on keys in the localization files.
    # Can be run on individual actions or entire controllers this way.
    #
    def set_page_title
      @page_title = I18n.t("title.#{controller_name}.#{action_name}")
    end

  private

    ### TODO: add json :unauthorized and proper WWW-Authenticate header based on auth method.
    def not_authenticated
    respond_to do |format|
      format.html { redirect_to login_path }
      format.any do
        response.headers['WWW-Authenticate'] = 'Token realm="Application"'
        head :unauthorized
      end
    end
    return false
  end

end
