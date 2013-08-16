
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
