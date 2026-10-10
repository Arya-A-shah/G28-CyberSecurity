#!/usr/bin/env bash
# Step 2 (report sections 4.3 and 4.4): confined users and separated admin roles.
#   lowuser   - user_u, clearance s1
#   analyst1  - user_u, clearance s1-s3, compartment c1
#   admin1    - staff_u, reaches sysadm_r only through sudo
#   secadm1   - security administrator (policy), secadm_r
#   auditadm1 - audit administrator (logs), auditadm_r
# Run as root after the MLS policy is active.
set -euo pipefail
cd "$(dirname "$0")/.."

# Every new Linux user defaults to the confined user_u SELinux user
semanage login -m -s user_u -r s0 __default__

# Clearance range for staff_u
semanage user -m -L s1 -r s1-s15 staff_u

# Ordinary users
useradd -Z user_u lowuser
semanage login -m -r s1 lowuser
useradd -Z user_u analyst1
semanage login -m -r s1-s3:c1 analyst1          # verify on target system

# Confined system administrator
useradd -Z staff_u admin1
semanage login -m -r s1-s3 admin1

# Separate security and audit administrators
useradd -Z staff_u secadm1
useradd -Z staff_u auditadm1                     # verify on target system

# Remove security-admin rights from sysadm_r so admin1 cannot change policy
semodule -d sysadm_secadm

# sudo role transitions
install -m 0440 sudoers/admin1    /etc/sudoers.d/admin1
install -m 0440 sudoers/secadm1   /etc/sudoers.d/secadm1
install -m 0440 sudoers/auditadm1 /etc/sudoers.d/auditadm1
visudo -c

# Admins may not log in over SSH directly as sysadm_r
setsebool -P ssh_sysadm_login off
setsebool -P user_exec_content off               # verify effect on target system

genhomedircon
restorecon -R -F -v /home/

semanage login -l
echo "Set passwords with: passwd lowuser / analyst1 / admin1 / secadm1 / auditadm1"
