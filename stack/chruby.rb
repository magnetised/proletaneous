package :chruby, provides: :ruby do
  version = "0.3.6"
  source "https://github.com/postmodern/chruby/archive/v#{version}.tar.gz" do
    custom_archive "chruby-#{version}.tar.gz"
    custom_install 'make install'
    post :install do
      config = "/etc/profile.d/00-chruby.sh"
      [
        %(echo '[ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] || return' > #{config}),
        %(echo 'source /usr/local/share/chruby/chruby.sh' >> #{config})
      ]
    end
  end
  verify do
    has_file "/usr/local/share/chruby/chruby.sh"
  end
  requires :ruby_version, opts
end

package :ruby_version do
  requires :ruby_install
  version = opts[:ruby_version]
  ruby    = opts[:ruby]
  install_dir =  "/opt/rubies/#{ruby}"
  runner "ruby-install ruby #{version}"
  runner %(#{install_dir}/bin/gem install bundler --no-rdoc --no-ri)
  runner %(echo "chruby #{ruby}" > /etc/profile.d/01-default-ruby.sh)
  verify do
    has_executable "#{install_dir}/bin/ruby"
  end
end

package :ruby_install do
  requires :curl
  version = "0.3.0"
  source "https://codeload.github.com/postmodern/ruby-install/tar.gz/v#{version}" do
    custom_archive "ruby-install-#{version}.tar.gz"
    custom_install 'make install'
  end
  verify do
    has_executable "/usr/local/bin/ruby-install"
  end
end

package :curl do
  apt "curl"
  verify do
    has_executable "/usr/bin/curl"
  end
end