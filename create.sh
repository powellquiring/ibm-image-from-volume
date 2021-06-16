#!/bin/bash
set -e
set -o pipefail
# todo
all="
000-prereqs.sh
010-terraform-a-create.sh
020-create-image.sh
030-terraform-b-create.sh
040-test.sh
"
for script in $all; do
  echo '>>>' $script
  ./$script
done
