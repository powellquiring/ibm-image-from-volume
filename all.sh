#!/bin/bash
set -e
set -o pipefail
# todo
for script in 0*.sh; do
# for script in 0[2-9]*.sh; do
  echo '>>>' $script
  ./$script
done
