package :essential do
  requires :build_essential
  requires :libxml
  requires :inotify_tools
  requires :misc_tools
end

package :build_essential do
  description 'Build tools & core libraries'
  pkg = %w(build-essential)
  apt pkg
  verify do
    pkg.each { |p| has_apt p }
  end
end

package :libxml do
  pkg = %w(libxml2 libxml2-dev libxslt1.1 libxslt1-dev)
  apt pkg
  verify do
    pkg.each { |p| has_apt p }
  end
end

package :inotify_tools do
  pkg = %w(inotify-tools)
  apt pkg
  verify do
    pkg.each { |p| has_apt p }
  end
end

package :misc_tools do
  pkg = %w(htop)
  apt pkg
  verify do
    pkg.each { |p| has_apt p }
  end
end