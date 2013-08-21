package :imagemagick, provides: :image_processing do
  apt %w(imagemagick)
  verify do
    has_apt "imagemagick"
  end
end