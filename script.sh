#!/bin/sh

PLUGIN_AWS_ACCESS_KEY=${PLUGIN_AWS_ACCESS_KEY:?'error: ACCESS_KEY is required'}
PLUGIN_AWS_SECRET_KEY=${PLUGIN_AWS_SECRET_KEY:?'error: SECRET_KEY is required'}
PLUGIN_AWS_REGION=${PLUGIN_AWS_REGION:?'error: AWS_REGION is required'}
PLUGIN_KUBECONFIG=${PLUGIN_KUBECONFIG:?'error: KUBECONFIG is required'}

export AWS_ACCESS_KEY_ID="$PLUGIN_AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$PLUGIN_AWS_SECRET_KEY"
export AWS_REGION="$PLUGIN_AWS_REGION"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
export DOCKER_SERVER="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export DOCKER_PASSWORD=$(aws ecr get-login --no-include-email --region "$AWS_REGION" | cut -d ' ' -f6)
export SECRET_NAME=${PLUGIN_SECRET_NAME:-aws-ecr-credentials}

# Create Kubeconfig file
mkdir -p ~/.kube
echo "$PLUGIN_KUBECONFIG" | base64 -d > ~/.kube/config

# Delete Kubernetes secret (if exists)
kubectl delete secret "$SECRET_NAME" --ignore-not-found

# Crete new Kubernetes secret
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-username=AWS \
  --docker-email=hello@docker.com \
  --docker-server="$DOCKER_SERVER" \
  --docker-password="$DOCKER_PASSWORD"
