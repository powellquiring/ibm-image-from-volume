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


for dir in terraform-a; do
(
  cd $dir
  echo '>>>' terraform destroy $dir
  terraform init
  terraform destroy -auto-approve
)
done
success=true
