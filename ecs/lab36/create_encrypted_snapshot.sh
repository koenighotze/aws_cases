#!/bin/sh

function wait_for_state() {
  wait_for=$1
  cmd=$2
  filter=$3

  state=""
  while [ "$state" != "$wait_for" ] ;
  do
    out=$($2)
    state=$(echo $out | jq -r "$3")
    echo "...state is '$state'"
    sleep 2
  done
}

echo Finding the running instance
instance_id=$(aws ec2 describe-instances --filters file://filter.json --query 'Reservations[*].Instances[*].[InstanceId]' | jq -r '.[0][0][0]')

echo Finding the volume
volume_id=$(aws ec2 describe-instances --filters file://filter.json  --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' | jq -r '.[0][0][0]')

echo Stopping instance $instance_id
aws ec2 stop-instances --instance-ids $instance_id

echo Waiting for instance $instance_id to stop...
cmd="aws ec2 describe-instance-status --include-all-instances --instance-ids $instance_id"
wait_for_state "stopped" "$cmd" '.[] | .[].InstanceState.Name'

echo Starting instance $instance_id
aws ec2 start-instances --instance-ids $instance_id

echo Creating a snapshot of volume $volume_id
snapshot_id=$(aws ec2 create-snapshot --volume-id $volume_id | jq -r '.SnapshotId')

echo Waiting until snapshot $snapshot_id is completed...
cmd="aws ec2 describe-snapshots --snapshot-id $snapshot_id"
wait_for_state "completed" "$cmd" '.Snapshots[0].State'

echo Creating an encrypted copy of snapshot $snapshot_id
encrypted_snapshot_id=$(aws ec2 copy-snapshot --source-snapshot-id $snapshot_id --source-region $AWS_DEFAULT_REGION --encrypted | jq -r '.SnapshotId')

echo Waiting until encrypted snapshot $encrypted_snapshot_id is completed...
cmd="aws ec2 describe-snapshots --snapshot-id $encrypted_snapshot_id"
wait_for_state "completed" "$cmd" '.Snapshots[0].State'

echo Deleting unencrypted snapshot $snapshot_id
aws ec2 delete-snapshot --snapshot-id $snapshot_id

echo Created an encrypted snapshot:
aws ec2 describe-snapshots --snapshot-ids $encrypted_snapshot_id | jq -r '.Snapshots[]'

echo Please cleanup:
echo aws ec2 delete-snapshot --snapshot-id $encrypted_snapshot_id