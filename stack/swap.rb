module HasSwapEnabledVerifier
  def has_swapfile(swapfile = '/swapfile')
    @commands << "swapon -s | grep #{swapfile}"
  end
end

Sprinkle::Verify.register(HasSwapEnabledVerifier)

package :swap do
  swapfile          = "/swapfile"
  memory_size       = "cat /proc/meminfo | awk '/^MemTotal/ { print $2 }' "
  generate_swapfile = "dd if=/dev/zero of=#{swapfile} bs=1024 count=$(#{memory_size})"
  set_permissions   = "chown root:root #{swapfile} && chmod 0600 #{swapfile}"

  runner %(if [ ! -f "#{swapfile}" ]; then #{generate_swapfile} && #{set_permissions}; fi)
  runner %(mkswap #{swapfile} && swapon #{swapfile})
  push_text "/swapfile       none    swap    sw      0       0", "/etc/fstab"
  runner "echo 0 > /proc/sys/vm/swappiness"

  verify do
    has_swapfile(swapfile)
    file_contains("/etc/fstab", swapfile)
  end
end