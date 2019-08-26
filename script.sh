#!/bin/sh

assert_not_empty() {
  local key="$1"
  local val="$2"
  if [[ -z "$val" ]]; then
    echo "[error]: $key is required"
    exit 1
  fi
}

create_kubeconfig() {
  local CONFIG_FILE="~/.kube/config"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p $(dirname "$CONFIG_FILE")
    assert_not_empty 'KUBECONFIG' "$PLUGIN_KUBECONFIG"
    echo "$PLUGIN_KUBECONFIG" | base64 -d > "$CONFIG_FILE"
  fi
}

create_k8s_secret() {
  kubectl delete secret "$SECRET_NAME" --ignore-not-found
  kubectl create secret docker-registry "$SECRET_NAME" \
    --docker-username=AWS \
    --docker-email=hello@docker.com \
    --docker-server="$DOCKER_SERVER" \
    --docker-password="$DOCKER_PASSWORD"
}

assert_not_empty 'ACCESS_KEY' "$PLUGIN_AWS_ACCESS_KEY"
assert_not_empty 'SECRET_KEY' "$PLUGIN_AWS_SECRET_KEY"
assert_not_empty 'AWS_REGION' "$PLUGIN_AWS_REGION"

export AWS_ACCESS_KEY_ID="$PLUGIN_AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$PLUGIN_AWS_SECRET_KEY"
export AWS_REGION="$PLUGIN_AWS_REGION"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
export DOCKER_PASSWORD=$(aws ecr get-login --no-include-email --region "$AWS_REGION" | cut -d ' ' -f6)
export DOCKER_SERVER="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export SECRET_NAME="${PLUGIN_SECRET_NAME:-aws-ecr-credentials}"

create_kubeconfig
create_k8s_secret
