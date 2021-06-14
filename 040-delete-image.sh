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

image_deleted() {
  local image_id=$1  
  local images_json=$(ibmcloud is images --visibility private --output json)
  image_json=$(jq -e '.[]|select(.id == "'$image_id'")' <<< "$images_json")
  ret=$?
  if [ $ret = 4 ]; then
    return 0; #true not found, it has been deleted
  fi
  if [ $ret != 0 ]; then
    echo jq failed to parse the following string: "$images_json"
    exit 1
  fi
  local status
  status=$(jq -r .status <<< "$image_json")
  case $status in
  available|deleting) false ;;
  *) echo expecting status x got $status; exit 1 ;;
  esac
  false
}

this_dir=$(dirname "$0")
source $this_dir/shared.sh

image_name=$TF_VAR_prefix

echo '>>>' finding image
images_json=$(ibmcloud is images --resource-group-name $TF_VAR_resource_group_NAME --output json)
if ! image_json=$(jq -e -r '.[]|select(.name == "'$image_name'")' <<< "$images_json"); then
  echo '>>>' image $image_name not found
else
  image_id=$(jq -r .id <<< "$image_json")
  image_status=$(jq -r .status <<< "$image_json")
  if [ $image_status = available ]; then
    echo '>>>' deleting image $image_id
    ibmcloud is image-delete --force $image_id
  fi
fi
echo '>>>' waiting for image to be deleted
wait_for_command "image_deleted $image_id"
success=true
