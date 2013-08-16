package :user do
  requires :create_shared_group, opts
  requires :create_user, opts
  requires :add_keys, opts
  requires :default_environment, opts
end

package :create_shared_group do
  @user, @group = opts[:user], opts[:group]
  add_group @group
  verify do
    has_group @group
  end
end

package :create_user do
  @user, @group = opts[:user], opts[:group]
  add_user  @user, :flags => "--disabled-password"
  runner "usermod -a -G #{@group} #{@user}"

  verify do
    has_user @user
  end
end

package :add_keys do
  ssh_dir = "/home/#{opts[:user]}/.ssh"
  authorized_keys = "#{ssh_dir}/authorized_keys"
  pub = %w(id_rsa.pub id_dsa.pub).map { |key| File.join(ENV['HOME'], '.ssh', key) }.detect { |file| File.exist?(file) }
  runner "test -d #{ssh_dir} || sudo -u #{opts[:user]} mkdir -p #{ssh_dir}"
  file authorized_keys, contents: File.read(pub), mode: "0600"
  runner "test -f #{authorized_keys} && chown #{opts[:user]}:#{opts[:user]} #{authorized_keys}"
  verify do
    has_file authorized_keys
  end
end

package :default_environment do
  file "/etc/profile.d/spontaneous_env.sh", contents: "export SPOT_ENV=production\n", mode: "0644"
  verify do
    has_file "/etc/profile.d/spontaneous_env.sh"
  end
end