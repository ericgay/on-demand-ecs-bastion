#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Please specify an aws profile name and path to a public key"
    echo "usage: ./login.sh aws-profile-name ecs-cluster-name ~/.ssh/keyfile.pub [options]"
    echo "e.g., to tunnel psql: '-L 54320:hostname:5432'"
    exit 1
fi

PROFILE=$1
CLUSTER=$2
SSH_PUBLIC_KEY=$(<$3)
OPTIONS=$4

TASK_NAME=bastion

echo Starting SSH bastion...

OVERRIDES="{ \"containerOverrides\": [ {  \"name\": \"bastion\", \"environment\": [ { \"name\": \"SSH_PUBLIC_KEY\", \"value\": \"${SSH_PUBLIC_KEY}\" } ] } ]}"
RUNTASK=$( aws ecs run-task --profile $PROFILE --launch-type "FARGATE" --cluster=$CLUSTER --task-definition=$TASK_NAME --overrides="$OVERRIDES" --network-configuration=awsvpcConfiguration='{subnets=["subnet-b9ae42e5"],securityGroups=["sg-01948bf26cb8e78d5"],assignPublicIp="ENABLED"}' --started-by "$(aws iam get-user --profile $PROFILE | jq -r '.User.UserName')" )
[ $? = 0 ] || exit 1

TASK_ID=$( echo "$RUNTASK" | jq -r '.tasks[0].taskArn' )
echo Started new Task: $TASK_ID

echo Waiting for task to be running...
aws ecs wait tasks-running --profile $PROFILE --tasks $TASK_ID --cluster $CLUSTER

ENI_ID=$( aws ecs describe-tasks --profile $PROFILE --cluster $CLUSTER --tasks $TASK_ID | jq -r '.tasks[0].attachments[0].details[1].value' )
echo Found network interface $ENI_ID

PUBLIC_IP=$(aws ec2 describe-network-interfaces --profile $PROFILE --network-interface-ids $ENI_ID | jq -r '.NetworkInterfaces[0].Association.PublicIp')

echo ssh $OPTIONS bastion@$PUBLIC_IP

ssh -A -o "StrictHostKeyChecking no" $OPTIONS bastion@$PUBLIC_IP

echo Stopping task...
aws ecs stop-task --profile $PROFILE --cluster $CLUSTER --task $TASK_ID >/dev/null

echo Waiting for task to stop...
aws ecs wait tasks-stopped --profile $PROFILE --tasks $TASK_ID --cluster $CLUSTER
echo Task stopped!
