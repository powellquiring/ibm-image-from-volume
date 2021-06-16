#!/bin/bash
set -e
set -o pipefail
# todo
all="
070-terraform-b-destroy.sh
080-delete-image.sh
090-terraform-a-destroy.sh
"
for script in $all; do
  echo '>>>' $script
  ./$script
done
