#!/bin/bash
set -euo pipefail
set -o errexit
# set -o errtrace
IFS=$'\n\t'

# export OBS_ACL=${OBS_ACL:-private}

mkdir -p ${MNT_POINT}

if [ "$OBSFS_IAM_ROLE" == "none" ]; then
  echo "${OBSFS_ACCESS_KEY}:${OBSFS_SECRET_KEY}" > /etc/passwd-obsfs
  chmod 0400 /etc/passwd-obsfs
  echo 'IAM_ROLE is not set - mounting OBSFS with credentials from ENV'
  /usr/bin/obsfs ${OBSFS_BUCKET} ${MNT_POINT} -d -d -f -o url=${OBSFS_ENDPOINT},allow_other,retries=5,passwd_file=/etc/passwd-obsfs
else
  echo 'IAM_ROLE is set - using it to mount OBSFS'
  /usr/bin/obsfs ${OBSFS_BUCKET} ${MNT_POINT} -d -d -f -o url=${OBSFS_ENDPOINT},iam_role=${IAM_ROLE},allow_other,retries=5
fi
