#!/usr/bin/env bash
# Step 3 (report sections 4.5 and 4.6): label repository data by level and compartment,
# and give each level its own /tmp (polyinstantiation).
# Run as root (as secadm1 once roles are separated).
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p /srv/repo/s1 /srv/repo/s3/progA /srv/repo/s3/progB
echo "routine report"              > /srv/repo/s1/notice.txt
echo "SECRET programme A document" > /srv/repo/s3/progA/doc_a.txt
echo "SECRET programme B document" > /srv/repo/s3/progB/doc_b.txt

# Persistent labels (regex form with -r: verify on target system)
semanage fcontext -a -r s1    "/srv/repo/s1(/.*)?"
semanage fcontext -a -r s3    "/srv/repo/s3(/.*)?"
semanage fcontext -a -r s3:c1 "/srv/repo/s3/progA(/.*)?"
semanage fcontext -a -r s3:c2 "/srv/repo/s3/progB(/.*)?"
restorecon -RFv /srv/repo
chmod -R a+rX /srv/repo      # DAC allows everyone, so any denial comes from MLS
ls -lZR /srv/repo

# Home directory of the low-clearance user
chcon -R -l s1 /home/lowuser

# Polyinstantiated /tmp and /var/tmp (one instance per level)
setsebool -P allow_polyinstantiation 1 || setsebool -P polyinstantiation_enabled 1
mkdir -p /tmp-inst /var/tmp/tmp-inst
chmod 000 /tmp-inst /var/tmp/tmp-inst
restorecon -Fv /tmp-inst /var/tmp/tmp-inst
cp config/namespace.conf /etc/security/namespace.conf
for f in su sudo sshd; do
  grep -q pam_namespace /etc/pam.d/$f || echo "session required pam_namespace.so unmnt_remnt" >> /etc/pam.d/$f
done
