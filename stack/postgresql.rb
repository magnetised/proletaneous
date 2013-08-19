
module HasDatabaseVerifier
  def has_database(db)
    @commands << "psql -t -l -U postgres | grep #{db}"
  end
end

Sprinkle::Verify.register(HasDatabaseVerifier)

package :postgres, :provides => :database do
  description 'PostgreSQL database'
  requires :install_postgres, opts
  requires :configure_postgres, opts
  requires :configure_authentication, opts
  requires :wal_e, opts
end

package :install_postgres do
  apt %w( postgresql postgresql-client libpq-dev )
  verify do
    has_executable 'psql'
  end
end

package :configure_postgres do
  shmmax = ( opts.fetch(:server_memory_mb, 512) / 2 ).to_i * 1024 * 1024
  file '/etc/sysctl.d/30-postgresql-shm.conf', contents: (<<-CONFIG).gsub(/^ +/, '') do
    # Shared memory settings for PostgreSQL

    # Note that if another program uses shared memory as well, you will have to
    # coordinate the size settings between the two.

    # Maximum size of shared memory segment in bytes
    kernel.shmmax = #{shmmax}

    # Maximum total size of shared memory in pages (normally 4096 bytes)
    kernel.shmall = #{shmmax / 4096}
  CONFIG
    post :install, 'service procps start'
  end
  @opts = opts
  @config = opts.fetch(:postgres_config, {})
  file '/etc/postgresql/9.1/main/postgresql.conf', contents: render(File.expand_path("../../templates/etc/postgresql/postgresql.conf", __FILE__)) do
    post :install, 'service postgresql restart'
  end
end


TRUST = 'local   all             %s                                     trust'

package :configure_authentication do
  hba =  '/etc/postgresql/9.1/main/pg_hba.conf'
  replace_text 'local   all             postgres                                peer', TRUST % ['postgres'], hba
  replace_text 'local   all             all                                     peer', TRUST % ['all'], hba do
    post :install, 'service postgresql restart'
  end
  verify do
    file_contains hba, (TRUST % ['all'])
  end
end

package :wal_e do
  requires :pipe_viewer, opts
  requires :lzop, opts
  requires :libevent, opts
  requires :wal_e_dependencies, opts
  requires :wal_e_env, opts
  requires :wal_e_command, opts
  requires :wal_e_crontab, opts
end

# make base backup every day @ 2am
package :wal_e_crontab do
  tmpfile = "/tmp/wal-e.cron"
  # need to delete older backups. something like the following will get the list of backup names
  #
  # $(/usr/bin/chpst -e /etc/wal-e.d/env /usr/local/bin/wal-e backup-list | sed '1d' | awk '{print $1}')
  #
  # then I need to run 'delete before':
  #
  # /usr/bin/chpst -e /etc/wal-e.d/env /usr/local/bin/wal-e delete before base_00000004000002DF000000A6_03626144
  crontab = [
     "0 2 * * * /usr/bin/chpst -e /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /var/lib/postgresql/9.1/main"
  ].join("\n")
  file tmpfile, contents: crontab << "\n"
  runner "crontab -u postgres #{tmpfile} ; rm #{tmpfile}"
end

package :wal_e_command do
  runner "easy_install wal-e"
  verify do
    has_executable "wal-e"
  end
end

package :wal_e_env do
  env_dir = "/etc/wal-e.d/env"
  env = opts[:production_env]
  if env # first run is without opts
    runner "test -d #{env_dir} || mkdir -p #{env_dir}"
    %w(WALE_AWS_ACCESS_KEY_ID WALE_AWS_SECRET_ACCESS_KEY WALE_WALE_S3_PREFIX).each do |k|
      raise "Missing environment setting '#{k}'" if !env.key?(k)
      key, value = k.gsub(/^WALE_/, ''), env[k]
      file "#{env_dir}/#{key}", contents: value, owner: "root:postgres", mode: "0640"
    end
  end
end

package :pipe_viewer do
  apt "pv"
  verify do
    has_apt "pv"
  end
end

package :lzop do
  apt "lzop"
  verify do
    has_apt "lzop"
  end
end

package :libevent do
  apt %w(libevent-dev libevent-core-2.0-5)
  verify do
    has_apt "libevent-dev"
  end
end

package :wal_e_dependencies do
  runner "easy_install boto"
  runner "easy_install gevent"
end