# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'chimerao'
set :repo_url, 'git@github.com:chimerao/backend.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/webapp/backend'

# Path to frontend web app
set :frontend_build_dir, '/home/webapp/frontend/build'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, [
    'config/database.yml',
    'config/secrets.yml'
  ]

# Default value for linked_dirs is []
set :linked_dirs, [
    'log',
    'tmp/pids',
    'tmp/cache',
    'tmp/sockets',
    'public/system'
  ]

# Front end files to check for
set :frontend_index_files, [
    "#{fetch(:frontend_build_dir)}/index.html",
    "#{fetch(:frontend_build_dir)}/js/main.js"
  ]

set :frontend_linked_dirs, [
    'css',
    'images',
    'js'
  ]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# We do not need to bundle everything into a shared directory
set :bundle_flags, '--quiet'

namespace :deploy do

  desc 'Check to see front end app is deployed'
  task :check_frontend do
    on roles(:all) do |host|
      next unless any? :frontend_index_files
      fetch(:frontend_index_files).each do |file|
        unless test "[ -f #{file} ]"
          error "#{file} does not exist on #{host}"
          exit 1
        end
      end
    end
  end

  before :starting, :check_frontend

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  namespace :symlink do

    'Symlink frontend files'
    task :frontend do
      on roles(:all) do |host|
        execute :ln, '-s',
          "#{fetch(:frontend_build_dir)}/index.html",
          "#{release_path}/app/views/layouts/application.html.raw"

        next unless any? :frontend_linked_dirs
        fetch(:frontend_linked_dirs).each do |dir|
          source = "#{fetch(:frontend_build_dir)}/#{dir}"
          target = release_path.join('public', dir)
          execute :ln, '-s', source, target
        end
      end
    end

  end

  after :publishing, 'symlink:frontend'

end
