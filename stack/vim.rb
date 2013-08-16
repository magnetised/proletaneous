package :vim, provides: :editor do
  apt "vim"
  verify do
    has_executable "/usr/bin/vim"
  end
end