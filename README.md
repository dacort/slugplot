# Slugplots with SparkR

Back in August 2020, I [tweeted out a visualization](https://twitter.com/dacort/status/1426317934964609024) that shows mean temperature change over time.

This repo contains the artifacts necessary to build your own on Amazon EMR.

## Overview

Included here is a Dockerfile with the necessary R libraries and a sample notebook that generates the visualization for Seattle.

You'll need to build an image, push it to ECR, then launch an EMR cluster that supports your ECR repository.

## Setting up

### Build and push container image

- Define your account and region

```shell
export AWS_ACCOUNT_ID=123456789012
export AWS_REGION=us-west-2
```

- Create an ECR repository (one-time only)

```shell
aws ecr create-repository --region ${AWS_REGION} \
    --repository-name emr-docker-sparkr
```

- Build and push

```shell
docker build -t local/sparkr .
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker tag local/sparkr ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/emr-docker-sparkr:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/emr-docker-sparkr:latest
```

### Start an EMR cluster

When running Docker containers on EMR, you need to allowlist the specific repositories.

**Note that we have a fairly large image and the first time you try to run the notebook, it may timeout while downloading the image. Just restart the kernel and try again. :)**

```shell
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-west-2
LOG_BUCKET=aws-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}
SUBNET_ID=subnet-123455678901234567

aws emr create-cluster --name "emr-docker" \
    --region us-east-1 \
    --release-label emr-6.5.0 \
    --enable-debugging \
    --log-uri "s3n://${LOG_BUCKET}/elasticmapreduce/" \
    --applications Name=Spark Name=Livy Name=JupyterEnterpriseGateway \
    --ec2-attributes SubnetId=${SUBNET_ID} \
    --use-default-roles \
    --instance-groups '[
    {
        "InstanceCount": 1,
        "EbsConfiguration": {
            "EbsBlockDeviceConfigs": [
                {
                    "VolumeSpecification": {
                        "SizeInGB": 32,
                        "VolumeType": "gp2"
                    },
                    "VolumesPerInstance": 4
                }
            ]
        },
        "InstanceGroupType": "MASTER",
        "InstanceType": "c5.2xlarge",
        "Name": "Master - 1"
    },
    {
        "InstanceCount": 8,
        "EbsConfiguration": {
            "EbsBlockDeviceConfigs": [
                {
                    "VolumeSpecification": {
                        "SizeInGB": 64,
                        "VolumeType": "gp2"
                    },
                    "VolumesPerInstance": 4
                }
            ]
        },
        "InstanceGroupType": "TASK",
        "InstanceType": "c5.4xlarge",
        "Name": "Task - 3"
    },
    {
        "InstanceCount": 2,
        "EbsConfiguration": {
            "EbsBlockDeviceConfigs": [
                {
                    "VolumeSpecification": {
                        "SizeInGB": 64,
                        "VolumeType": "gp2"
                    },
                    "VolumesPerInstance": 4
                }
            ]
        },
        "InstanceGroupType": "CORE",
        "InstanceType": "c5.4xlarge",
        "Name": "Core - 2"
    }]' \
    --configurations '[
    {
        "Classification": "container-executor",
        "Configurations": [
            {
                "Classification": "docker",
                "Properties": {
                    "docker.trusted.registries": "local,'${ACCOUNT_ID}'.dkr.ecr.'${REGION}'.amazonaws.com",
                    "docker.privileged-containers.registries": "local,'${ACCOUNT_ID}'.dkr.ecr.'${REGION}'.amazonaws.com"
                }
            }
        ]
    }
]'
```