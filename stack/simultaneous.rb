package :simultaneous do
  @simultaneous_version = opts[:simultaneous_version]
  root = '/root/simultaneous'
  runner "test -d #{root} || mkdir #{root}"
  file "#{root}/Gemfile", content: render(File.expand_path("../../templates/root/simultaneous/Gemfile", __FILE__)) do
  end
  requires :simultaneous_install, opts.merge(simultaneous_root: root)
  requires :simultaneous_runit, opts.merge(simultaneous_root: root)
  runner "sv restart simultaneous"
end

package :simultaneous_install do
  root = opts[:simultaneous_root]
  ruby = "/opt/rubies/#{opts[:ruby]}"

  runner "cd #{root} && #{ruby}/bin/bundle install --without development --standalone --binstubs --shebang #{ruby}/bin/ruby"
end


package :simultaneous_runit do
  available = "/etc/sv"
  enabled = "/etc/service"
  name = "simultaneous"
  service =  "#{available}/#{name}"
  log     =  "#{available}/#{name}/log"
  runner "test -d #{service} || mkdir #{service}"
  runner "test -d #{log}/main || mkdir -p #{log}/main"
  @ruby = opts[:ruby]
  @root = opts[:simultaneous_root]
  @socket = opts[:simultaneous_socket]
  file "#{service}/run", contents: render(File.expand_path("../../templates/etc/sv/simultaneous/run", __FILE__)), mode: "0755"
  file "#{log}/run", contents: File.read(File.expand_path("../../templates/sv-log-run", __FILE__)), mode: "0755"
  runner "ln -nfs #{available}/#{name} #{enabled}"
end

