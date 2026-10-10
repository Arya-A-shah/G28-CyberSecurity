#!/usr/bin/env bash
# Step 1 (report section 4.2): install the SELinux MLS policy and switch to it.
# Boots in permissive mode first so denials can be reviewed before enforcing.
# Run as root on a fresh Rocky Linux 9 / RHEL 9 VM without a graphical desktop.
set -euo pipefail

dnf install -y selinux-policy-mls policycoreutils-python-utils setools-console usbguard audit

# Use the MLS policy in permissive mode for the first boot
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=mls/' /etc/selinux/config

# Relabel the whole file system on next boot
fixfiles -F onboot

echo "MLS policy configured (permissive). Reboot now, then run:"
echo "  sestatus | grep mls"
echo "  ausearch -m AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR -ts recent -i"
echo "Fix any denials, set SELINUX=enforcing in /etc/selinux/config and reboot again."
