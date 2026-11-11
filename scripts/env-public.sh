# scripts/env.sh - source this in every new terminal:  source scripts/env.sh
# Edit the two values below. This file contains no secrets.

export LAB_AWS_PROFILE="rosalab"        # your AWS CLI profile name
export LAB_AWS_REGION="us-east-1"       # the region you use for everything

export AWS_PROFILE="$LAB_AWS_PROFILE"
export AWS_REGION="$LAB_AWS_REGION"

# Stale static or temporary credentials in the environment override the profile, so clear them.
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

lab-start() {
  echo "== AWS =="
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS session missing or expired, logging in..."
    aws login --profile "$AWS_PROFILE" || return 1
  fi
  # This prints your IAM user's ARN, which contains your account ID. Keep it out of notes.
  aws sts get-caller-identity --query Arn --output text

  echo
  echo "== Red Hat / ROSA =="
  if ! rosa whoami >/dev/null 2>&1; then
    echo "Not logged in to Red Hat, logging in..."
    rosa login --use-auth-code || return 1
  fi
  rosa whoami >/dev/null 2>&1 && echo "Red Hat login OK"

  echo
  echo "== Kubernetes context =="
  kubectl config current-context 2>/dev/null || echo "(none set)"

  echo
  echo "== ROSA clusters (these bill hourly) =="
  rosa list clusters
}
