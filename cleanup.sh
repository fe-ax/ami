#!/bin/bash

DATE_THRESHOLD=$(date --date="7 days ago" '+%Y-%m-%d')
AMIS_TO_DELETE=$(aws ec2 describe-images --owners self --filters "Name=tag:Creator,Values=Packer" --query 'Images[?CreationDate<=`'"$DATE_THRESHOLD"'`].[ImageId]' --output text)

for AMI in $AMIS_TO_DELETE; do
    REGEX="^ami-[a-zA-Z0-9]+$"
    if [[ $AMI =~ $REGEX ]]; then
        echo "Deregistering AMI: $AMI"
        echo "Deregistering AMI: $AMI" >> $GITHUB_STEP_SUMMARY
        aws ec2 deregister-image --image-id "$AMI"
        
        SNAPSHOTS_TO_DELETE=$(aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:Creator,Values=Packer" --filters "Name=description,Values=*$AMI*" --query 'Snapshots[*].SnapshotId' --output text)
        
        for SNAPSHOT in $SNAPSHOTS_TO_DELETE; do
            echo "Deleting snapshot: $SNAPSHOT"
            echo "Deleting snapshot: $SNAPSHOT" >> $GITHUB_STEP_SUMMARY
            aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT"
        done
    else
        echo "Wrong AMI format: $AMI"
    fi
done

echo "Completed deregistering" >> $GITHUB_STEP_SUMMARY
