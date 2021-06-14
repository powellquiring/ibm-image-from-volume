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

instance_stopped() {
  local instance_id=$1  
  local instance_json=$(ibmcloud is instance $instance_id --output json)
  local status=$(jq -r .status <<< "$instance_json")
  case $status in
  stopped) true;;
  running|stopping) false;;
  *) jq . <<< "$instance_json"; echo instance creation resulted in unknown status expecting running or stopping got: $status; exit 1;;
  esac
}
instance_running() {
  local instance_id=$1  
  local instance_json=$(ibmcloud is instance $instance_id --output json)
  local status=$(jq -r .status <<< "$instance_json")
  case $status in
  running) true;;
  starting|stopped) false;;
  *) jq . <<< "$instance_json"; echo instance creation resulted in unknown status expecting running or starting got: $status; exit 1;;
  esac
}
image_available() {
  local image_id=$1  
  local image_json=$(ibmcloud is image $image_id --output json)
  local status=$(jq -r .status <<< "$image_json")
  case $status in
  available) true;;
  starting|stopped) false;;
  *) jq . <<< "$instance_json"; echo instance creation resulted in unknown status expecting running or starting got: $status; exit 1;;
  esac
}


this_dir=$(dirname "$0")
source $this_dir/shared.sh

image_name=$TF_VAR_prefix

instance_id=$(read_terraform_variable instance_id)
echo '>>>' stopping instance $instance_id before creating the image
ibmcloud is instance-stop --force $instance_id

echo '>>>' wait for the instance to be stopped
wait_for_command "instance_stopped $instance_id"

echo '>>>' create image
boot_volume_id=$(read_terraform_variable boot_volume_id)
image_json=$(ibmcloud is image-create $image_name --source-volume $boot_volume_id --output json)

echo '>>>' waiting for image to be available
image_id=$(jq -r .id <<< "$image_json")
wait_for_command "image_available $image_id"


ibmcloud is instance-start $instance_id
wait_for_command "instance_running $instance_id"



success=true
