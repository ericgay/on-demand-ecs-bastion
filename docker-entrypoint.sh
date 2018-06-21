#!/bin/bash
set -e

if [[ -z "${SSH_PUBLIC_KEY}" ]]; then
  echo "No SSH_PUBLIC_KEY set"
  # TODO, copy from s3, but not needed for now
else
  echo $SSH_PUBLIC_KEY >> /home/bastion/.ssh/authorized_keys
fi

exec "$@"
