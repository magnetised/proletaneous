package :git, :provides => :scm do
  description 'Git Distributed Version Control'
  apt 'git'

  verify do
    has_executable "/usr/bin/git"
  end
  requires :ssh_auth_sock
end

package :ssh_auth_sock do
  push_text 'Defaults     env_keep+=SSH_AUTH_SOCK', '/etc/sudoers'
  verify do
    file_contains '/etc/sudoers', 'SSH_AUTH_SOCK'
  end
end