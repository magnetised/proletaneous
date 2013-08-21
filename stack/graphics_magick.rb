# graphics magick has some incompatibilities with imagemagick
# and since Skeptick assumes imagemagick it's better that we install that
package :graphics_magic, provides: :image_processing do
  apt %w(graphicsmagick graphicsmagick-imagemagick-compat graphicsmagick-libmagick-dev-compat)
  verify do
    has_apt "graphicsmagick"
  end
end
