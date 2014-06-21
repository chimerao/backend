module ApplicationHelper

  # Checks to see if there's a specific Javascript file related to the
  # controller. Used in header templates.
  #
  def controller_has_javascript?(name)
    File.exist?(File.join(Rails.root, 'app', 'assets', 'javascripts', name + '.js'))
  end

  # Checks to see if there's a specific CSS file related to the
  # controller. Used in header templates.
  #
  def controller_has_stylesheet?(name)
    File.exist?(File.join(Rails.root, 'app', 'assets', 'stylesheets', name + '.css'))
  end

  # Returns the javascript tag for the non-English locale .js file if another locale
  # is selected. en is always loaded by default as a fallback in application.html.erb.
  #
  def locale_javascript_include_tag
    if I18n.locale != :en and File.exist?(File.join(Rails.root, 'app', 'assets', 'javascripts', 'locales', I18n.locale.to_s + '.js'))
      return javascript_include_tag("locales/#{I18n.locale.to_s}.js")
    end
  end

  # Displays the flash notices, giving them a different id (color) for
  # each different response. success = green, error = red, etc.
  #
  def notice
    if flash[:success]
      %{<div class="flash" id="success">#{flash[:success]}</div>}
    elsif flash[:error]
      %{<div class="flash" id="error">#{flash[:error]}</div>}
    elsif flash[:warning] or flash[:alert]
      %{<div class="flash" id="warning">#{flash[:warning] or flash[:alert]}</div>}
    elsif flash[:notice]
      %{<div class="flash" id="notice">#{flash[:notice]}</div>}
    end
  end

  # Displays the time relative to now. e.g. '1 hour ago', '8 days ago', etc.
  # This accepts two arguments:
  # time - This is the time that you want translated.
  # length - How deep do you want to go in describing it? By default, this is
  # month (e.g. '1 year, 3 months ago'). However, this method will go as far
  # as it needs to in order to display the time in the most relevant format.
  # In otherwords, if the time is 5 minutes ago, it display "5 minutes ago"
  # instead of defaulting to "0 months ago"
  #
  # Constant for use in the time_ago method.
  #
  TIMEBLOCKS = {
    :second => 1,
    :minute => 60,
    :hour => 60 * 60,
    :day => 60 * 60 * 24,
    :week => 60 * 60 * 24 * 7,
    :month => 60 * 60 * 24 * 30,
    :year => 60 * 60 * 24 * 365
  }

  def time_ago(time, length = 'month')
    if time > 2.weeks.ago
      time_periods = TIMEBLOCKS.sort_by { |k, v| v }.collect { |t| t.first.to_s }.reverse
      relative_times = []
      seconds_ago = Time.now - time
      seconds_ago = 1 if seconds_ago < 1 # To prevent a blank time.
      time_periods.each do |t|
        interval = TIMEBLOCKS[t.to_sym]
        if seconds_ago >= interval
          val = (seconds_ago / interval).to_i
          seconds_ago -= val * interval
          relative_times << "#{val} #{t}#{'s' if val > 1}"
        end
        if val
          break if time_periods.index(length) <= time_periods.index(t)
        end
      end
      return relative_times.join(', ') + ' ago'
    else
      if time > Time.now.at_beginning_of_year
        return time.strftime("%B %e")
      else
        return time.strftime("%B %e, %Y")
      end
    end
  end

  # Renders the approprite style for a Thumbnail, dynmically generated from
  # its properties. Primarily used to vertical align without aid of a table.
  # Accepts Thumbnail class objects only.
  #
  # :padding is the default padding for the image
  # :size is in case we want to force thumbnail size. However, beware that
  #   the styles are set via dynamically generated css in application.html.erb,
  #   so they too will need to be manually specified.
  #
  def thumbnail_style(thumbnail, options = {})
    padding = options[:padding] || 10
    options[:size] ||= thumbnail_size
    pixels = options[:size]
    if thumbnail.landscape?
      top = (pixels - ((pixels.to_f / thumbnail.orig_width) * thumbnail.orig_height).to_i) / 2 + padding
    else # portrait
      top = padding
    end
    "position:relative;top:#{top}px;"
  end

  # Renders the appopriate style for a Thumbnail's metadata, dynamically
  # generated from its properties. Accepts Thumbnail class objects only.
  #
  # :size is in case we want to force a thumbnail size. Beware that styles
  #   are set via dynamically generated css in application.html.erb, so they
  #   would also need to be adjusted.
  #
  def thumbnail_data_style(thumbnail, options = {})
    top_adjustment = 24
    options[:size] ||= thumbnail_size
    pixels = options[:size]
    right = 4;
    if thumbnail.landscape?
      top = (pixels - ((pixels.to_f / thumbnail.orig_width) * thumbnail.orig_height).to_i) / 2 + top_adjustment
    else # portrait
      top = top_adjustment
      right = (pixels - ((pixels.to_f / thumbnail.orig_height) * thumbnail.orig_width).to_i) / 2 + 4
    end
    "top:#{top}px;right:#{right}px;"
  end

  # Formats text for HTML display. Uses redcarpet gem for markdown output.
  # Also makes sure things like # and @ tags are linked.
  #
  def imaginate_format(text)
    return '' if text.nil?
    redcarpet_extensions = {
      :autolink => true,
      :filter_html => true,
      :hard_wrap => true,
      :space_after_headers => true
    }
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, redcarpet_extensions)
    html = markdown.render(text)

    # Any alterations to the HTML (such as tag links) must be done AFTER the
    # initial markdown render, because that strips html from the text.
    #
    # Make all #tags links
    #
    html.gsub!(/(^|(?<=\s)|(?<=[\-\*\!\^\?\_\+\.\(\),;'"><~]))#(\w+)/, '<a href="/submissions/tagged/\2">\0</a>')

    # Make all @profiles links
    #
    html.gsub!(/(^|(?<=\s)|(?<=\W))@(\w+)/, '<a href="/\2">\0</a>')

    html.html_safe
  end

  # Takes a tag_list array and displays it with links.
  #
  def display_tags(tag_list)
    tag_list.collect { |tag| link_to("\##{tag}", tagged_submissions_path(tag)) }.join(' ').html_safe
  end

  # Central method for formatting the host url.
  # This is needed for manual route descriptions in the API primarily.
  # Useful for development and testing, what with their ports and all.
  #
  def imaginate_host_url
    "#{request.protocol}#{request.host_with_port}"
  end

  # A convenience method to display the full URL for Paperclip attachments
  #
  def paperclip_url(path)
    "#{imaginate_host_url}#{path}"
  end
end
