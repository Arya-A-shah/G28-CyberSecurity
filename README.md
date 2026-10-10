# SELinux MAC as Defense-in-Depth: Snowden Counterfactual Testbed

Code for the Cyber Security CA-2 case study **"Mandatory Access Control Using SELinux as a Defense-in-Depth Mechanism: A Counterfactual Case Study of the Edward Snowden NSA Breach"** (Group 28, B.Tech CSE, Semester VII, Batch 2023–27).

The report asks which stages of the 2012–13 Snowden breach a properly configured SELinux system would have prevented, contained or detected. This repository contains the testbed described in **Section 4 (Implementation Details)** of the report, so the expected results in Table 3 can be checked on a real machine.

## Team

| Name | PRN |
| --- | --- |
| Arya Bhirud | 23070122050 |
| Arya Amit Shah | 23070122051 |
| Bishwajeet Sahoo | 23070122073 |
| Dakshit Singh | 23070122078 |

## What the testbed shows

| Attack stage (report) | Control in this repo | Expected result |
| --- | --- | --- |
| Admin browsing other users' data (S2) | MLS levels and categories | Denied outside the user's clearance |
| Copying classified data to USB (S7) | USBGuard + MLS no write-down | Blocked |
| One admin disabling SELinux or wiping logs (A1) | `sysadm_secadm` removed, `secadm_r` / `auditadm_r` split, `auditctl -e 2` | Denied |
| Logging bypass on the workstation (S5) | Kernel audit rules on the data host | Still logged |

SELinux cannot stop collection within a user's own clearance, use of borrowed passwords, or booting with `enforcing=0`. Those need other layers (smartcards, monitoring, Secure Boot). See report Section 5.3.

## Repository structure

```
scripts/
  01_enable_mls.sh        install and switch to the MLS policy (section 4.2)
  02_create_users.sh      confined users and separated admin roles (4.3, 4.4)
  03_label_data.sh        label data by level/compartment, polyinstantiation (4.5, 4.6)
  04_usb_and_audit.sh     USBGuard, locked enforcement, audit rules (4.7–4.9)
sudoers/                  sudo role transitions for admin1, secadm1, auditadm1
config/                   namespace.conf and the USBGuard block rule
audit/99-case-study.rules audit rules, locked with -e 2
policy/                   separation-of-duties test modules (4.10)
tests/run_tests.sh        test plan T1–T8 (Table 3)
```

## Requirements

- A virtual machine running **Rocky Linux 9** or **RHEL 9**, with no graphical desktop (Red Hat advises against X under MLS)
- Root access and a VM snapshot taken before you start
- Optional: a USB stick passed through to the VM for the removable-media tests

## Setup

```bash
git clone <this-repo-url> && cd selinux-snowden-mac
sudo bash scripts/01_enable_mls.sh
sudo reboot
# check: sestatus | grep mls ; fix denials, set SELINUX=enforcing, reboot

sudo bash scripts/02_create_users.sh
sudo bash scripts/03_label_data.sh
sudo bash scripts/04_usb_and_audit.sh
```

## Running the tests

Log in on the VM console (not SSH) as each test user and run:

```bash
bash tests/run_tests.sh
```

| Test | Run as | Action | Expected |
| --- | --- | --- | --- |
| T1 | lowuser | Read a file in `/srv/repo/s3` | Denied, AVC record |
| T2 | analyst1 | Read the `progB` (c2) compartment | Denied |
| T3 | analyst1 | Copy `progA` data to `/srv/repo/s1` | Denied (no write-down) |
| T4 | analyst1 | Write to an s0-labelled USB mount | Denied (no write-down) |
| T5 | admin1 | Plug in a USB storage device | Blocked by USBGuard |
| T6 | admin1 | `setenforce 0` or load a policy module | Denied |
| T7 | admin1 | `auditctl -D` after `-e 2` | Fails, configuration locked |
| T8 | auditadm1 | `ausearch -k admin_snoop` | Root read logged with original login uid |

View denials as the audit administrator: `ausearch -m AVC -ts recent -i`

## Notes

- The results in the report are analytical. These scripts are the plan for confirming them, and the expected outcomes above still need to be checked on your VM.
- Lines marked `verify on target system` were composed for this study rather than copied from Red Hat's documentation.
- `secure_mode_policyload` and `auditctl -e 2` stay in force until reboot. Test on a snapshot.
- For anything beyond a lab VM, also set a GRUB password and enable Secure Boot.

## References

- Red Hat, *RHEL 9: Using SELinux*, ch. 3 (confined users), ch. 6 (MLS), ch. 8 (custom policy)
- USBGuard Project, *Rule language* documentation
- `auditctl(8)` Linux manual page
- U.S. House Permanent Select Committee on Intelligence, *Review of the Unauthorized Disclosures of Former NSA Contractor Edward Snowden*, H. Rept. 114-891, 2016

Full reference list: see the report (35 references).
