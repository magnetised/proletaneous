package :nginx, :provides => :webserver do
  requires :runit
  description "Nginx webserver"
  apt "nginx" do
    post :install do
     ["update-rc.d nginx disable", "rm /etc/nginx/sites-enabled/*"]
    end
  end
  verify do
    has_apt 'nginx'
  end
  requires :nginx_config, opts
  requires :nginx_runit, opts
end

package :nginx_config do
  file "/etc/nginx/nginx.conf", contents: File.read(File.expand_path("../../templates/etc/nginx/nginx.conf", __FILE__))
end

package :nginx_runit do
  available = "/etc/sv"
  enabled = "/etc/service"
  name = "nginx"
  service =  "#{available}/#{name}"
  runner "test -d #{service} || mkdir #{service}"
  file "#{service}/run", contents: render(File.expand_path("../../templates/etc/sv/nginx/run", __FILE__)), mode: "0755"
  runner "ln -nfs #{available}/#{name} #{enabled}/#{name}"
end