#!/bin/sh
snapshot_id=${1:?Please enter id}
aws ec2 describe-volumes --filter Name=snapshot-id,Values=${snapshot_id} | jq '.Volumes[0].State'