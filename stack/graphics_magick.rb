package :graphics_magic, provides: :image_processing do
  apt %w(graphicsmagick graphicsmagick-imagemagick-compat graphicsmagick-libmagick-dev-compat)
  verify do
    has_apt "graphicsmagick"
  end
  requires :image_optimization, opts
end

package :image_optimization do
  apt %(jpegoptim pngcrush)
  verify do
    has_apt "jpegoptim"
  end
end