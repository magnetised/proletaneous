package :spontaneous do
  config = {
    home: "/home/#{opts[:user]}",
    app_root: "/home/#{opts[:user]}/spontaneous",
    back_socket: "/tmp/#{ opts[:site_id] }_back.sock",
    front_socket: "/tmp/#{ opts[:site_id] }_front.sock"
  }
  requires :app_skeleton,   opts.merge(config)
  requires :cached_copy,    opts.merge(config)
  requires :release,        opts.merge(config)
  requires :dependencies,   opts.merge(config)
  requires :site_env,       opts.merge(config)
  requires :user_services,  opts.merge(config)
  requires :site_nginx_config,  opts.merge(config)
  requires :publish_monitoring,  opts.merge(config)
end

package :app_skeleton do
  @user = opts[:user]
  @home = opts[:home]
  @app_root = opts[:app_root]
  directories = %w(config/env media revisions uploadcache releases shared/log shared/tmp shared/pids shared/system).map { |subdir| "#{@app_root}/#{subdir}" }

  directories.each do |dir|
    runner "test -d #{dir} || sudo -u #{@user} mkdir -p #{dir}"
  end

  publish_log = "#{@app_root}/shared/log/publish.log"
  runner "sudo -u #{@user} touch #{publish_log}"

  verify do
    directories.each { |d| has_directory(d)  }
    has_file publish_log
  end
end

package :cached_copy do
  requires :initial_checkout, opts
  cached_copy = "#{opts[:app_root]}/shared/cached-copy"
  runner "(cd #{cached_copy} &&  git pull && chown -R #{opts[:user]}:#{opts[:user]} #{cached_copy})"
end

package :initial_checkout do
  @user = opts[:user]
  @home = opts[:home]
  app_root = opts[:app_root]
  cached_copy = "#{app_root}/shared/cached-copy"
  runner "git clone #{opts[:repository]} #{cached_copy}"
  runner "chown -R #{@user}:#{@user} #{cached_copy}"

  verify do
    has_directory  "#{app_root}/shared/cached-copy"
  end
end


package :release do
  app_root = opts[:app_root]
  now = Time.now.strftime('%Y%m%d%H%M%S')
  cached_copy = "#{app_root}/shared/cached-copy"
  release = "#{app_root}/releases/#{now}"
  runner "sudo -u #{opts[:user]} mkdir -p #{release}"
  runner "(cd #{cached_copy} && sudo -u #{opts[:user]} git clone --depth=1 #{cached_copy} #{release})"
  runner "sudo -u #{opts[:user]} git --git-dir=#{cached_copy}/.git log -1 --pretty=format:%H > #{release}/REVISION"
  runner "sudo -u #{opts[:user]} ln -s #{release} #{app_root}/current"
  verify do
    has_directory "#{app_root}/current"
  end
end

package :dependencies do
  release = "#{opts[:app_root]}/current"
  # to make this work we need to enable key forwarding to work when using sudo
  # see http://serverfault.com/questions/107187/sudo-su-username-while-keeping-ssh-key-forwarding
  runner "chmod -R a+wrx `dirname $SSH_AUTH_SOCK`"
  runner "(cd #{release} && sudo -u #{opts[:user]} bash -c 'echo $SSH_AUTH_SOCK && source /usr/local/share/chruby/chruby.sh && chruby #{opts[:ruby]} && bundle install --without development --binstubs --deployment --shebang ${RUBY_ROOT}/bin/ruby')"
  runner "(cd #{release} && sudo -u #{opts[:user]} ./bin/spot init --environment=production --user=postgres --create-user=false)"
  config = YAML.load_file(File.expand_path('../../../database.yml', __FILE__))[:production]
  verify do
    has_executable "#{release}/bin/spot"
    has_database   config[:database]
  end
end

package :site_env do
  environment = {
    "SPOT_ENV" => "production",
    "SIMULTANEOUS_SOCKET" => opts[:simultaneous_socket],
    "SPONTANEOUS_BINARY" => "#{opts[:app_root]}/current/bin/spot",
    "SPONTANEOUS_SERVER" => opts[:back_socket],
    "RUBY_BIN" => "/opt/rubies/#{opts[:ruby]}/bin/ruby"
  }.merge(opts[:environment] || {})
  env_dir = "#{opts[:app_root]}/config/env"

  environment.each do |key, value|
    next if value.nil?
    file File.join(env_dir, key), contents: value, owner: "#{opts[:user]}:#{opts[:user]}"
  end
end

package :user_services do
  requires :runit
  @user = user = opts[:user]
  @home = opts[:home]
  @spontaneous = opts[:app_root]
  @current = "#{@spontaneous}/current"
  @back_socket = opts[:back_socket]
  @front_socket = opts[:front_socket]
  @ruby = opts[:ruby]

  runner "test -d /etc/sv/#{@user}/log/main || mkdir -p /etc/sv/#{@user}/log/main"
  file "/etc/sv/#{@user}/run", contents: render(File.expand_path("../../templates/etc/sv/home/run", __FILE__)), mode: "0755"
  file "/etc/sv/#{@user}/log/run", contents: File.read(File.expand_path("../../templates/sv-log-run", __FILE__)), mode: "0755"

  enabled = "#{@home}/service/enabled"

  runner "test -d #{enabled} || sudo -u #{@user} mkdir -p #{enabled}"

  %w(back front).each do |service|
    sv = "#{@home}/service/available/#{service}"
    runner "test -d #{sv}/log/main || sudo -u #{@user} mkdir -p #{sv}/log/main"
    file "#{sv}/run", contents: render(File.expand_path("../../templates/home/services/#{service}/run", __FILE__)),
      owner: [@user, @user].join(":"), mode: "0755" do
      # this command often returns an error because the process takes too long to quit (hence the 'force-' part)
      # however this error is (usually..) spurious so we can just ignore it with the '|| true'
      post :install, "cd #{enabled} && sudo -u #{user} /usr/bin/sv force-restart ./#{service} || true"
    end
    file "#{sv}/log/run", contents: File.read(File.expand_path("../../templates/sv-log-run", __FILE__)), owner: [@user, @user].join(":"), mode: "0755" do
      post :install, "cd #{enabled} && sudo -u #{user} /usr/bin/sv force-restart ./#{service}/log || true"
    end
    runner "sudo -u #{@user} ln -nfs #{sv} #{enabled}"
  end

  runner "ln -nfs /etc/sv/#{@user} /etc/service"
end

package :site_nginx_config do
  @home = opts[:home]
  @spontaneous = "#{@home}/spontaneous"
  @current = "#{@spontaneous}/current"
  @back_socket = opts[:back_socket]
  @front_socket = opts[:front_socket]
  @opts = opts
  %w(back front).each do |service|
    conf = "#{opts[:site_id]}-#{service}.conf"
    file "/etc/nginx/sites-available/#{conf}", contents: render(File.expand_path("../../templates/etc/nginx/#{service}.conf", __FILE__))
    runner "ln -nfs /etc/nginx/sites-available/#{conf} /etc/nginx/sites-enabled/#{conf}" do
      post :install, ""
    end
  end

end

package :publish_monitoring do
  @user = user = opts[:user]
  @home = opts[:home]
  @spontaneous = "#{@home}/spontaneous"
  @revision_file ="#{ @spontaneous }/revisions/REVISION"
  service = "publish"
  sv = "#{@home}/service/available/#{service}"
  enabled = "#{@home}/service/enabled"
  runner "if [ ! -f \"#{@revision_file}\" ]; then sudo -u #{user} touch #{@revision_file}; fi"
  runner "test -d #{sv}/log/main || sudo -u #{@user} mkdir -p #{sv}/log/main"

  file "#{sv}/run", contents: render(File.expand_path("../../templates/home/services/#{service}/run", __FILE__)), owner: [@user, @user].join(":"), mode: "0755" do
    post :install, "if [ -d \"#{enabled}/#{service}\" ];then cd #{enabled} && sudo -u #{user} /usr/bin/sv restart ./#{service}; fi"
  end

  file "#{sv}/finish", contents: render(File.expand_path("../../templates/home/services/#{service}/finish", __FILE__)), owner: [@user, @user].join(":"), mode: "0755"

  file "#{sv}/log/run", contents: File.read(File.expand_path("../../templates/sv-log-run", __FILE__)), owner: [@user, @user].join(":"), mode: "0755" do
    # post :install, "test -d #{enabled}/#{service}/log && cd #{enabled} && sudo -u #{user} /usr/bin/sv restart ./#{service}/log"
    post :install, "if [ -d \"#{enabled}/#{service}/log\" ];then cd #{enabled} && sudo -u #{user} /usr/bin/sv restart ./#{service}/log; fi"
  end
  runner "sudo -u #{@user} ln -nfs #{sv} #{enabled}"
end
