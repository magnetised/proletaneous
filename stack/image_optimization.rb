package :image_optimization do
  apt %(jpegoptim pngcrush)
  verify do
    has_apt "jpegoptim"
  end
end