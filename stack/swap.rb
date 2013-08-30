# Implement this
package :swap do
  # sudo swapon -s                                          # test for swap...
  # sudo dd if=/dev/zero of=/swapfile bs=1024 count=512k    # create an empty file
  # sudo chown root:root /swapfile
  # sudo chmod 0600 /swapfile
  # sudo mkswap /swapfile
  # sudo swapon /swapfile
  # echo "/swapfile       none    swap    sw      0       0" >> /etc/fstab
end