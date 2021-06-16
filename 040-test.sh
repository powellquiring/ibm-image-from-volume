#!/bin/bash
set -e
set -o pipefail

success=false
trap check_finish EXIT
check_finish() {
  if [ $success = true ]; then
    echo '>>>' success
  else
    echo "FAILED"
  fi
}

this_dir=$(dirname "$0")
source $this_dir/shared.sh

floating_ip=$(read_terraform_b_variable floating_ip)
echo '>>>' verify the /version.txt file exists at $floating_ip
ssh_it $floating_ip <<'SSH'
  set -ex
  cat /version.txt
  source /version.txt
  [ x$version = x1 ]
SSH
cat <<< "$ssh_it_out_and_err"
success=true
