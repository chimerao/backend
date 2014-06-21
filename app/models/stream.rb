class Stream < ActiveRecord::Base
  belongs_to :profile
  has_many :favorites, as: :favable, dependent: :destroy

  validates :name, :rules, presence: true
  validates :name, length: { maximum: 40 }

  scope :permanent, -> { where(is_permanent: true) }
  scope :non_permanent, -> { where(is_permanent: false) }
  scope :are_public, -> { where(is_public: true) }

  after_save :set_privacy

  def profile_can_view?(p)
    is_public?
  end

  def include_submissions?
    rules.include?('submissions:all')
  end

  def include_journals?
    rules.include?('journals:all')
  end

  def limited_to_following?
    rules.include?('profiles:followed')
  end

  def limited_to_profile?
    is_permanent
  end

  def deliver(options = {})
    viewing_profile = options.delete(:for_profile)
    per_page = options.delete(:per_page) || 10
    page = options.delete(:page) || 1

    submissions = tasks.find { |task| task.include?('submissions') }
    journals    = tasks.find { |task| task.include?('journals') }
    favorites   = tasks.find { |task| task.include?('favorites') }
    comments    = tasks.find { |task| task.include?('comments') }
    shares      = tasks.find { |task| task.include?('shares') }
    follows     = tasks.find { |task| task.include?('follows') }

    tagged = tasks.find { |task| task.include?('tags') }
    tags = tagged.split(':').last.split(',') if tagged

    none = tasks.select { |task| task.include?('none') }.join(' ')

    items = []

    if none and !none.blank?
      submissions = "submissions:all" if !none.include?('submissions')
      journals = "journals:all" if !none.include?('journal')
    #   # if profiles_only
    #   #   favorites = "favorites:all" if !none.include?('favorites')
    #   #   comments = "comments:all" if !none.include?('comments')
    #   #   shares = "shares:all" if !none.include?('shares')
    #   #   follows = "follows:all" if !none.include?('follows')
    #   # end
    end

    # This means get ALL relevant global content.
    # favorites and comments are not considered part of this
    #
    if !submissions and !journals and !favorites and !comments and !shares and !follows
      submissions = "submissions:all"
      journals = "journals:all"
    end

    if submissions
      rule_scope = submissions.split(':').last
      if rule_scope == 'profile'
        items << Submission.filtered_for_profile(viewing_profile, for_profile: profile)
      elsif rule_scope == 'all'
        if profiles_only?
          profiles.each do |followed_profile|
            if viewing_profile
              if tagged
                items << Submission.filtered_for_profile(viewing_profile, for_profile: followed_profile, tags: tags)
              else
                items << Submission.filtered_for_profile(viewing_profile, for_profile: followed_profile)
              end
            else
              if tagged
                items << followed_profile.collaborated_submissions.unfiltered.published.tagged_with(tags)
              else
                items << followed_profile.collaborated_submissions.unfiltered.published
              end
            end
          end
        else
          if viewing_profile
            if tagged
              items << Submission.filtered_for_profile(viewing_profile, tags: tags)
            else
              items << Submission.filtered_for_profile(viewing_profile)
            end
          else
            if tagged
              items << Submission.unfiltered.published.tagged_with(tags)
            else
              items << Submission.unfiltered.published
            end
          end
        end
      end
    end

    if journals
      rule_scope = journals.split(':').last
      if rule_scope == 'profile'
        items << profile.journals.filtered_for_profile(viewing_profile).published
      elsif rule_scope == 'all'
        if profiles_only?
          profiles.each do |followed_profile|
            if viewing_profile
              if tagged
                items << followed_profile.journals.filtered_for_profile(viewing_profile).published.tagged_with(tags) #, for_profile: followed_profile, tags: tags)
              else
                items << followed_profile.journals.filtered_for_profile(viewing_profile).published #, for_profile: followed_profile)
              end
            else
              if tagged
                items << followed_profile.journals.unfiltered.published.tagged_with(tags)
              else
                items << followed_profile.journals.unfiltered.published
              end
            end
          end
        else
          if viewing_profile
            if tagged
              items << Journal.filtered_for_profile(viewing_profile).published.tagged_with(tags) #, tags: tags)
            else
              items << Journal.filtered_for_profile(viewing_profile).published
            end
          else
            if tagged
              items << Journal.published.unfiltered.tagged_with(tags)
            else
              items << Journal.published.unfiltered
            end
          end
        end
      end
    end

    items << favorite_items
    items << comment_items
    items << share_items

    # if follows
    #   rule_scope = follows.split(':').last
    #   if rule_scope == 'profile'
    #     items << profile.is_watching
    #   elsif profiles_only and rule_scope == 'all'
    #     profiles.each do |p|
    #       items << p.is_watching
    #     end
    #   end
    # end

    items.flatten!
    items = items.sort_by { |item| item.respond_to?('published_at') ? item.published_at : item.created_at }
    items.reverse!
    tidbits = items.collect { |item| Tidbit.new(targetable: item, profile: profile, created_at: item.respond_to?('published_at') ? item.published_at : item.created_at) }

    if page.to_i == 1 && tidbits.size <= per_page.to_i
      return tidbits
    elsif tidbits.size >= (page.to_i - 1) * per_page.to_i
      return tidbits[((page.to_i - 1) * per_page.to_i)..((page.to_i * per_page.to_i) - 1)]
    else
      return []
    end
  end

  private

    def set_privacy
      # First off, no permanent (default) streams can be set private.
      update_attribute(:is_public, true) if is_permanent? && !is_public?
      
      # If set private, all favorites of it should be removed.
      if !is_public?
        favorites.each { |favorite| favorite.destroy }
      end    
    end

    def tasks
      rules.downcase.split(' ')
    end

    def profiles
      profile_task = tasks.find { |task| task.include?('profiles') }
      profile_tags = nil

      if profile_task
        rule_scope = profile_task.split(':')[1]
        if rule_scope == 'followed'
          profiles_only = true
        elsif rule_scope == 'tagged'
          profiles_only = true
          profile_tags = profile_task.split(':').last
        end
        if profile_tags
          profiles = profile.following_profiles.tagged_with(profile_tags, on: :relations)
        else
          profiles = profile.following_profiles
        end
      else
        profiles = nil
      end

      return profiles
    end

    def profiles_only?
      !profiles.nil?
    end

    def favorite_items
      items = []
      favorites = tasks.find { |task| task.include?('favorites') }

      if favorites
        rule_scope = favorites.split(':').last
        if rule_scope == 'profile'
          items << profile.favorites.filtered_submissions
          items << profile.favorites.filtered_journals
        elsif profiles_only? && rule_scope != 'none'
          profile_ids = profiles.collect { |p| p.id }
          favorite_streams = Stream.where(profile_id: profile_ids, name: 'Favorites')
          favorite_streams.each do |favorite_stream|
            items << favorite_stream.deliver
          end
        end
      end

      return items
    end

    def comment_items
      items = []
      comments = tasks.find { |task| task.include?('comments') }

      if comments
        rule_scope = comments.split(':').last
        if rule_scope == 'profile'
          items << profile.comments.filtered_submissions
          items << profile.comments.filtered_journals
        elsif profiles_only? && rule_scope != 'none'
          profile_ids = profiles.collect { |p| p.id }
          comment_streams = Stream.where(profile_id: profile_ids, name: 'Comments')
          comment_streams.each do |comment_stream|
            items << comment_stream.deliver
          end
        end
      end

      return items
    end

    def share_items
      items = []
      shares = tasks.find { |task| task.include?('shares') }

      if shares
        rule_scope = shares.split(':').last
        if rule_scope == 'profile'
          items << profile.shares.filtered_submissions
          items << profile.shares.filtered_journals
        elsif profiles_only? && rule_scope != 'none'
          profile_ids = profiles.collect { |p| p.id }
          share_streams = Stream.where(profile_id: profile_ids, name: 'Shares')
          share_streams.each do |share_stream|
            items << share_stream.deliver
          end
        end
      end

      return items
    end
end
