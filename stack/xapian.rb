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
  apt %(libxapian22 libxapian-dev)
  verify do
    has_apt "libxapian22"
    has_apt "libxapian-dev"
  end
end