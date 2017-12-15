
package :letsencrypt do
  requires :software_properties_common, opts
  requires :certbot_ppa, opts
  requires :certbot_post_deploy_hook, opts
  requires :certbot_renewal_cron, opts
end

package :software_properties_common do
  pkgs = %w(software-properties-common)
  apt pkgs
  verify do
    pkgs.each { |pkg| has_apt(pkg) }
  end
end


package :certbot_ppa do
  runner "add-apt-repository ppa:certbot/certbot"
  runner "apt-get update"
  apt "python-certbot-nginx"
  verify do
    has_apt "python-certbot-nginx"
  end
end

package :certbot_post_deploy_hook do
  script = [
    "#!/bin/bash",
    "/usr/sbin/nginx -s reload",
  ].join("\n")
  file "/etc/letsencrypt/renewal-hooks/deploy/00-reload-nginx.sh", contents: (script << "\n"), mode: "0755"
end

package :certbot_renewal_cron do
  tmpfile = "/tmp/certbot.cron"
  crontab = [
    "# Renew certbot certificates daily",
    "12 4 * * * /usr/bin/certbot renew --quiet",
  ].join("\n")
  file tmpfile, contents: crontab << "\n"
  runner "crontab -u root #{tmpfile} ; rm #{tmpfile}"
end
