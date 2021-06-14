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


(
  cd terraform-a
  terraform init
  terraform apply -auto-approve
)

# wait for instance to finish the cloud init process
floating_ip=$(read_terraform_variable floating_ip)
echo '>>>' Last step: ssh to the instance, $floating_ip,  and wait for cloud-init to complete before continuing
ssh_it $floating_ip <<SSH
  set -ex
  cloud-init status --wait
SSH
cat <<< "$ssh_it_out_and_err"
success=true
