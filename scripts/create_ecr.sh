#!/usr/bin/env bash
# ==============================================================================
# create_ecr.sh — Create an Amazon ECR repository with security best practices
#
# Usage:
#   ./scripts/create_ecr.sh <repo-name> [--region <region>] [--env <dev|stage|prod>]
#
# Examples:
#   ./scripts/create_ecr.sh financeguard
#   ./scripts/create_ecr.sh financeguard --region us-west-2
#   ./scripts/create_ecr.sh financeguard --env prod
#   ./scripts/create_ecr.sh financeguard --region us-east-1 --env stage
# ==============================================================================

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
DEFAULT_REGION="us-east-1"
DEFAULT_ENV="dev"
PROJECT="aws-eks-openTel-pci-dss"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Helper functions ──────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <repo-name> [OPTIONS]

Create an Amazon ECR repository with PCI-DSS compliant defaults:
  • Image tag immutability enabled
  • Scan-on-push enabled
  • AES-256 encryption (KMS available via flag)
  • Lifecycle policy to expire untagged images after 14 days
  • Resource tagging for cost allocation and compliance

Arguments:
  repo-name              Name of the ECR repository to create

Options:
  --region <region>      AWS region (default: ${DEFAULT_REGION})
  --env <environment>    Target environment: dev, stage, prod (default: ${DEFAULT_ENV})
  --kms-key <key-arn>    Use KMS encryption with the given key ARN (default: AES-256)
  --mutable-tags         Allow mutable image tags (not recommended for prod)
  --no-scan              Disable scan-on-push (not recommended)
  --dry-run              Print the AWS CLI commands without executing
  -h, --help             Show this help message

Examples:
  $(basename "$0") financeguard
  $(basename "$0") financeguard --region us-west-2 --env prod
  $(basename "$0") financeguard --env prod --kms-key arn:aws:kms:us-east-1:123456789012:key/abc-123
EOF
  exit 0
}

# ── Parse arguments ───────────────────────────────────────────────────────────
REPO_NAME=""
REGION="${DEFAULT_REGION}"
ENVIRONMENT="${DEFAULT_ENV}"
KMS_KEY=""
TAG_IMMUTABILITY="IMMUTABLE"
SCAN_ON_PUSH=true
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --region)
      REGION="$2"; shift 2
      ;;
    --env)
      ENVIRONMENT="$2"; shift 2
      ;;
    --kms-key)
      KMS_KEY="$2"; shift 2
      ;;
    --mutable-tags)
      TAG_IMMUTABILITY="MUTABLE"; shift
      ;;
    --no-scan)
      SCAN_ON_PUSH=false; shift
      ;;
    --dry-run)
      DRY_RUN=true; shift
      ;;
    -*)
      error "Unknown option: $1"
      echo ""
      usage
      ;;
    *)
      if [[ -z "${REPO_NAME}" ]]; then
        REPO_NAME="$1"; shift
      else
        error "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
done

# ── Validate inputs ──────────────────────────────────────────────────────────
if [[ -z "${REPO_NAME}" ]]; then
  error "Repository name is required."
  echo ""
  usage
fi

if [[ ! "${ENVIRONMENT}" =~ ^(dev|stage|prod)$ ]]; then
  error "Environment must be one of: dev, stage, prod"
  exit 1
fi

# Check AWS CLI is available
if ! command -v aws &>/dev/null; then
  error "AWS CLI is not installed. See: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi

# ── Build encryption config ──────────────────────────────────────────────────
if [[ -n "${KMS_KEY}" ]]; then
  ENCRYPTION_CONFIG="encryptionType=KMS,kmsKey=${KMS_KEY}"
  ENCRYPTION_DISPLAY="KMS (${KMS_KEY})"
else
  ENCRYPTION_CONFIG="encryptionType=AES256"
  ENCRYPTION_DISPLAY="AES-256"
fi

# ── Build tags ────────────────────────────────────────────────────────────────
TAGS="Key=Project,Value=${PROJECT} Key=Environment,Value=${ENVIRONMENT} Key=ManagedBy,Value=Script Key=CreatedAt,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── Lifecycle policy (expire untagged images after 14 days) ───────────────────
LIFECYCLE_POLICY='{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images after 14 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep only last 50 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v", "sha-"],
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}'

# ── Print summary ─────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "ECR Repository Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Repository:     ${GREEN}${REPO_NAME}${NC}"
echo -e "  Region:         ${REGION}"
echo -e "  Environment:    ${ENVIRONMENT}"
echo -e "  Tag Mutability: ${TAG_IMMUTABILITY}"
echo -e "  Scan on Push:   ${SCAN_ON_PUSH}"
echo -e "  Encryption:     ${ENCRYPTION_DISPLAY}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Execute or dry-run ────────────────────────────────────────────────────────
run_cmd() {
  if [[ "${DRY_RUN}" == true ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
  else
    eval "$@"
  fi
}

# Step 1: Check if repository already exists
info "Checking if repository '${REPO_NAME}' already exists..."
if aws ecr describe-repositories \
    --repository-names "${REPO_NAME}" \
    --region "${REGION}" &>/dev/null; then
  warn "Repository '${REPO_NAME}' already exists in ${REGION}."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REPO_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"
  echo ""
  success "Existing repository URI: ${REPO_URI}"
  echo ""

  # Still apply lifecycle policy and tags to existing repo
  info "Updating lifecycle policy..."
  run_cmd "aws ecr put-lifecycle-policy \
    --repository-name '${REPO_NAME}' \
    --lifecycle-policy-text '${LIFECYCLE_POLICY}' \
    --region '${REGION}' \
    --output text > /dev/null"
  success "Lifecycle policy updated."

  info "Updating tags..."
  REPO_ARN=$(aws ecr describe-repositories \
    --repository-names "${REPO_NAME}" \
    --region "${REGION}" \
    --query "repositories[0].repositoryArn" \
    --output text)
  run_cmd "aws ecr tag-resource \
    --resource-arn '${REPO_ARN}' \
    --tags ${TAGS} \
    --region '${REGION}'"
  success "Tags updated."
  exit 0
fi

# Step 2: Create the repository
info "Creating ECR repository '${REPO_NAME}'..."
run_cmd "aws ecr create-repository \
  --repository-name '${REPO_NAME}' \
  --region '${REGION}' \
  --image-tag-mutability '${TAG_IMMUTABILITY}' \
  --image-scanning-configuration scanOnPush=${SCAN_ON_PUSH} \
  --encryption-configuration '${ENCRYPTION_CONFIG}' \
  --tags ${TAGS} \
  --output json"

if [[ "${DRY_RUN}" == false ]]; then
  success "Repository '${REPO_NAME}' created successfully."
else
  echo ""
fi

# Step 3: Apply lifecycle policy
info "Applying lifecycle policy..."
run_cmd "aws ecr put-lifecycle-policy \
  --repository-name '${REPO_NAME}' \
  --lifecycle-policy-text '${LIFECYCLE_POLICY}' \
  --region '${REGION}' \
  --output text > /dev/null"

if [[ "${DRY_RUN}" == false ]]; then
  success "Lifecycle policy applied."
fi

# Step 4: Print final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "${DRY_RUN}" == false ]]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REPO_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

  success "ECR repository ready!"
  echo ""
  echo -e "  Repository URI: ${GREEN}${REPO_URI}${NC}"
  echo ""
  echo "  Quick start:"
  echo "  ─────────────"
  echo "  # Authenticate Docker to ECR"
  echo "  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${REPO_URI%%/*}"
  echo ""
  echo "  # Tag and push an image"
  echo "  docker tag my-app:latest ${REPO_URI}:v1.0.0"
  echo "  docker push ${REPO_URI}:v1.0.0"
else
  info "Dry run complete — no resources were created."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
