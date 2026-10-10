#!/usr/bin/env bash
# Step 4 (report sections 4.7 to 4.9): removable-media control, locked
# enforcement and tamper-resistant auditing.
# Run as root. Test secure_mode_policyload on a VM snapshot first.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- USBGuard: allow devices present now, block mass storage from now on ---
usbguard generate-policy > /etc/usbguard/rules.conf      # verify on target system
cat config/usbguard-extra.rules >> /etc/usbguard/rules.conf
chmod 0600 /etc/usbguard/rules.conf
systemctl enable --now usbguard

# --- Audit rules, made immutable until reboot (-e 2 is the last line) ---
install -m 0640 audit/99-case-study.rules /etc/audit/rules.d/99-case-study.rules
augenrules --load
auditctl -s

# --- Lock the enforcement state ---
setsebool -P deny_ptrace on                               # verify on target system
setsebool secure_mode_policyload on                       # no -P: test first, then persist

echo "Remember: set a GRUB password and enable Secure Boot, otherwise"
echo "booting with enforcing=0 bypasses every setting above."
