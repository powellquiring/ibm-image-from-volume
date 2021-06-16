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
  pending) false;;
  *) jq . <<< "$image_json"; echo instance creation resulted in unknown status expecting running or starting got: $status; exit 1;;
  esac
}

this_dir=$(dirname "$0")
source $this_dir/shared.sh

image_name=$TF_VAR_image_name

instance_id=$(read_terraform_a_variable instance_id)
image_key_crn=$(read_terraform_a_variable image_key_crn)
boot_volume_id=$(read_terraform_a_variable boot_volume_id)
echo '>>>' Volume id $boot_volume_id must be attached to instance id $instance_id and encryption key crn will be $image_key_crn

echo '>>>' stopping instance $instance_id before creating the image
ibmcloud is instance-stop --force $instance_id

echo '>>>' wait for the instance to be stopped
wait_for_command "instance_stopped $instance_id"



echo '>>>' verify image name $image_name does not exist
images_json=$(ibmcloud is images --visibility private --output json)
if image_json=$(jq -e '.[]|select(.name=="'$image_name'")' <<< "$images_json"); then
  image_id=$(jq -r .id <<< "$image_json")
  echo image with image name $image_name already exists and has id $image_id
  existing_boot_volume_id=$(jq -r .source_volume.id <<< "$image_json")
  if [ $existing_boot_volume_id == $boot_volume_id ]; then
    echo verified image created from expected volume $boot_volume_id
  else
    echo existing image id $image_id has a boot volume $existing_boot_volume_id does not match expected boot volume $boot_volume_id
    exit 1
  fi
else
  echo '>>>' ibmcloud is image-create $image_name --source-volume $boot_volume_id --encryption-key-volume $image_key_crn
  image_json=$(ibmcloud is image-create $image_name --source-volume $boot_volume_id --encryption-key-volume $image_key_crn --output json)
  image_id=$(jq -r .id <<< "$image_json")
fi

echo '>>>' waiting for image $image_id to be available
wait_for_command "image_available $image_id"


echo '>>>' start instance $instance_id
ibmcloud is instance-start $instance_id

echo '>>>' waiting for image $image_id to be available
wait_for_command "instance_running $instance_id"

success=true
