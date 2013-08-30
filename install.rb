# Install a spontaneous stack onto the server configured in config/deploy.rb
# The same server could potentially host multiple sites
# so anything that happens here should try to respect any shared state
# The only case I can think of that might cause problems is the
# simultaneous server installation where different sites could be built
# against different Gem versions.

$:<< File.join(File.dirname(__FILE__))

%w(swap essential scm system_update imagemagick image_optimization xapian postgresql nginx runit chruby simultaneous user spontaneous).each do |lib|
  require "stack/#{lib}"
end

# Let vim provide the :editor package
require 'stack/vim'

# Get current simultaneous version
require 'simultaneous'

# Use dotenv to load production env settings
require 'dotenv'

# install the version of ruby that we're using to develop locally
ruby_version = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
ruby         = "ruby-#{ruby_version}"


opts = {
  ruby_version: ruby_version,
  ruby: ruby,
  simultaneous_version: Simultaneous::VERSION,
  simultaneous_socket: Simultaneous::DEFAULT_CONNECTION,
  group: 'spontaneous',
  # additional site env settings
  environment: {},
  secure: false
}

policy :db, roles: :db do
  requires :database, {}, opts
end

policy :spontaneous, roles: :app do
  # REENABLE AFTER DEV
  # requires :system_update
  requires :swap,               {}, opts
  requires :essential
  requires :editor
  requires :scm
  requires :image_processing,   {}, opts
  requires :image_optimization, {}, opts
  requires :search,             {}, opts
  # Slightly weird params... the first hash are taken as opts for sprinkle
  # the second is passed to the package itself
  requires :ruby,         {}, opts
  requires :simultaneous, {}, opts
  requires :user,         {}, opts
  requires :webserver,    {}, opts
  requires :spontaneous,  {}, opts
end

deployment do
  delivery :capistrano do
    begin
      recipes 'config/deploy'
    rescue LoadError
      $stderr.puts "Unable to load 'deploy'"
      exit 1
    end
    # this runs in a Capistrano::Config context so we can override config here
    # run as root for installation

    opts[:ruby_version] = fetch(:ruby_version, opts[:ruby_version])
    opts[:user]       = fetch(:user)
    opts[:repository] = fetch(:repository)
    opts[:domain]     = fetch(:domain)
    opts[:cms_host]   = fetch(:cms)
    opts[:site_id]    = fetch(:domain).to_s.gsub(/\./, '_')
    # http://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server
    # I'm mostly making the numbers up. Without the ability to introspect the
    # server state/config a la Chef there's no good way to provide server-specific
    # values without hand-coding
    server_memory = fetch(:server_memory_mb)
    opts[:server_memory_mb] = server_memory
    opts[:postgres_config] = {
      shared_buffers: (server_memory * 0.15).to_i, # If you have less RAM ... 15% is more typical there
      effective_cache_size: 80, # On UNIX-like systems, add the free+cached numbers from free or top to get an estimate
    }.merge(fetch(:postgres_config, {}))
    set :user, 'root'

    env = Dotenv::Environment.new(fetch(:production_env_file)) if File.exist?(fetch(:production_env_file))
    opts[:production_env] = env
  end

  source do
    prefix   '/usr/local'
    archives '/usr/local/sources'
    builds   '/usr/local/build'
  end
end