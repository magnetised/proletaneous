package :system_update do
  description "Update package lists & upgrade installed packages"
  runner "apt-get update && apt-get upgrade -y"
end