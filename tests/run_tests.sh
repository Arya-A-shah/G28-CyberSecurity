#!/usr/bin/env bash
# Test plan T1-T8 (report Table 3).
# Log in as each test user on the VM console (not SSH) and run:  bash tests/run_tests.sh
# The script picks the tests for whoever is logged in and prints PASS when the
# access is denied as the report expects. Save the output as evidence.

cd "$(dirname "$0")/.." || exit 1
USER_NOW=$(id -un)
echo "User: $USER_NOW   Context: $(id -Z)"
echo "-------------------------------------------------------------"

expect_denied() {   # $1 = test id, $2 = description, rest = command
  local id="$1" desc="$2"; shift 2
  if "$@" >/dev/null 2>&1; then
    echo "[$id] FAIL  $desc  (command succeeded)"
  else
    echo "[$id] PASS  $desc  (denied as expected)"
  fi
}

case "$USER_NOW" in
  lowuser)
    expect_denied T1 "s1 user reads s3 file" cat /srv/repo/s3/progA/doc_a.txt
    ;;
  analyst1)
    expect_denied T2 "s3:c1 user reads c2 compartment" cat /srv/repo/s3/progB/doc_b.txt
    expect_denied T3 "write-down from s3 to s1" cp /srv/repo/s3/progA/doc_a.txt /srv/repo/s1/leak.txt
    if mountpoint -q /mnt/media; then
      expect_denied T4 "write-down to s0 USB mount" cp /srv/repo/s3/progA/doc_a.txt /mnt/media/leak.txt
    else
      echo "[T4] SKIP  mount approved media at /mnt/media with an s0 context first"
    fi
    ;;
  admin1)
    echo "[T5] MANUAL plug in a USB stick, then check: sudo usbguard list-devices --blocked"
    expect_denied T6 "sysadm_r turns SELinux off" sudo setenforce 0
    expect_denied T6b "sysadm_r loads write-down module" sudo semodule -i policy/local_mlsfilewrite.cil
    sudo semodule -r local_mlsfilewrite >/dev/null 2>&1   # clean up if it was loaded
    expect_denied T7 "sysadm_r deletes audit rules" sudo auditctl -D
    sudo cat /srv/repo/s1/notice.txt >/dev/null 2>&1    # generates the T8 audit record
    echo "[T8] CHECK as auditadm1: ausearch -k admin_snoop -i  (should show admin1's login uid)"
    ;;
  *)
    echo "Run this as lowuser, analyst1 or admin1."
    ;;
esac

echo "-------------------------------------------------------------"
echo "Denials are logged. As auditadm1:  ausearch -m AVC -ts recent -i"
