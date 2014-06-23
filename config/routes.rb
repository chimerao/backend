Chimerao::Application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Root just shows all submissions. For now.
  #
  root 'submissions#index'

  # Special tag search for submissions. Needs to be above resoures definitions.
  #
  get '/submissions/tagged/:tag_name' => 'submissions#tagged', as: :tagged_submissions

  # Primary resources
  #
  resources :profiles, except: [:destroy] do
    get 'stream' => 'streams#stream', as: :stream_feed
    post 'banner' => 'profiles#banner'
    delete 'banner' => 'profiles#banner'
    resources :filters do
      member do
        post 'join'
        delete 'join' => 'filters#leave', as: :leave
      end
      resources :filter_profiles, only: [:index, :create, :destroy], as: :members, path: 'members' do
        member do
          get 'review_join', path: 'approve'
          post 'approve'
          delete 'decline', path: 'approve'
        end
      end
    end
    resources :messages do
      patch 'mark_read', on: :member
      collection do
        delete 'bulk_delete'
        patch 'bulk_archive'
        patch 'bulk_mark_read'
      end
    end
    resources :notifications, only: :index
    resources :journal_images, only: [:index, :create, :destroy]
    resources :profile_journals, except: [:show], as: :journals, path: 'journals' do
      member do
        patch 'publish'
        get 'series', as: :new_series
      end
      get 'unpublished', on: :collection
      resources :journal_images, only: [:index], as: :images, path: 'images'
    end
    resources :profile_pics, only: [:index, :show, :create, :destroy], as: :pics, path: 'pics' do
      patch 'make_default', on: :member
    end
    resources :profile_tags, only: [:index, :create, :destroy], as: :tags, path: 'tags'
    resources :profile_submissions, except: [:show], as: :submissions, path: 'submissions' do
      member do
        patch 'publish'
        get 'series', as: :new_series
      end
      collection do
        post 'multicreate'
        get 'unpublished'
        post 'group'
      end
    end
    resources :streams do
      member do
        post 'fave' => 'stream_favorites#create'
        delete 'fave' => 'stream_favorites#destroy', as: :unfave
      end
      collection do
        patch 'customize'
      end
    end
    resources :submission_folders
    resources :favorite_folders
    member do
      post 'switch'
      post 'follow'
      delete 'follow' => 'profiles#unfollow', as: :unfollow
    end
  end
  resources :submissions, only: [:index, :show] do
    member do
      post 'fave' => 'submission_favorites#create'
      delete 'fave' => 'submission_favorites#destroy', as: :unfave
      post 'share' => 'submission_shares#create'
      delete 'share' => 'submission_shares#destroy', as: :unshare
      post 'reply', path: 'reply/:replyable_type'
      get 'approval', path: 'approve', as: :review_approve
      post 'approve'
      delete 'decline', path: 'approve'
      get 'request_claim', path: 'claim'
      post 'claim'
      post 'relinquish'
      get 'review_relinquish', path: 'relinquish'
    end
    resources :submission_comments, only: [:index, :create, :destroy], as: :comments, path: 'comments'
  end
  resources :journals, only: [:show] do
    member do
      post 'fave' => 'journal_favorites#create'
      delete 'fave' => 'journal_favorites#destroy', as: :unfave
      post 'share' => 'journal_shares#create'
      delete 'share' => 'journal_shares#destroy', as: :unshare
      post 'reply', path: 'reply/:replyable_type'
    end
    resources :journal_comments, only: [:index, :create, :destroy], as: :comments, path: 'comments'
  end
  resources :users, only: [:index, :new, :create, :edit, :update], path: 'user'
  resources :comments, except: [:index, :show, :new, :edit, :create, :update, :destroy] do
    member do
      post 'vote' => 'comment_votes#create'
      delete 'vote' => 'comment_votes#destroy', as: :unvote
    end
  end
#  resources :communities, except: [:destroy] do
#    resources :community_members, except: [:show, :edit, :create], as: :members, path: 'members' do
#      post '' => 'community_members#create', on: :member, as: :add
#    end
#    resources :community_posts, as: :posts, path: 'posts'
#  end

  # Cleaner URIs for login/logout
  #
  get     'login'  => 'user_sessions#new',      as: :login
  post    'login'  => 'user_sessions#create',   as: :user_sessions
  delete  'logout' => 'user_sessions#destroy',  as: :logout
  get     'signup' => 'users#new',              as: :sign_up

  # Dash for streams, just an easier URI for folks to remember.
  #
  get 'dash' => 'streams#index'

  # Finally, any path after the root, if it does not exist, should point to a profile.
  #
  get ':site_identifier' => 'profiles#show', as: :profile_home

  get '*path', to: 'errors#catch_404'

#  scope ':site_identifier', as: :named do
#    resources :profile_submissions, as: :submissions, path: 'submissions'
#    resources :profile_journals, as: :journals, path: 'journals'
#  end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
