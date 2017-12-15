package :xapian, provides: :search do
  requires :xapian_dependencies, opts
  requires :xapian_library, opts
end

package :xapian_dependencies do
  pkgs = %w(uuid-dev)
  pkgs.each { |pkg| apt pkg }
  verify do
    pkgs.each { |pkg| has_apt pkg }
  end
end

package :xapian_library do
  packages = %w(libxapian22v5 libxapian-dev)
  apt packages
  verify do
    packages.each { |package| has_apt package }
  end
end
