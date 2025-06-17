#!/bin/bash

which ! aws &> /dev/null && {
  echo "aws cli is not installed. Please install it and try again."
  exit 1
}

BUCKET_NAME="${1}"
REGION="${2}"
RC_FILE="${3}"

aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$REGION 
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket $BUCKET_NAME

