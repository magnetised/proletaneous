package :runit, provides: :process_manager do
  apt "runit"
  verify do
    has_apt "runit"
  end
end
