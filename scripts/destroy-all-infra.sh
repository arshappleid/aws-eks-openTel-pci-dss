#!/usr/bin/env bash

# This script destroys all EKS PCI-DSS infrastructure across all environments (dev, stage, prod, shared)
# in the correct dependency order to prevent resource isolation or deletion errors.

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logger functions
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Usage message
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Destroys all Terraform-managed infrastructure in the correct order:
  1. dev (kubernetes -> compute -> network)
  2. stage (kubernetes -> compute -> network)
  3. prod (kubernetes -> compute -> network)
  4. shared (compute -> network)

Options:
  -y, --yes, --force     Skip confirmation prompt (non-interactive)
  --dry-run              Print the folders and commands that would be executed without running them
  -h, --help             Show this help message

EOF
  exit 0
}

# Parse options
AUTO_APPROVE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -y|--yes|--force)
      AUTO_APPROVE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      error "Unknown option: $1"
      echo ""
      usage
      ;;
  esac
done

# Check if terraform is installed
if ! command -v terraform &>/dev/null; then
  error "Terraform CLI is not installed. Please install it to proceed."
  exit 1
fi

# Define the absolute workspace root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${WORKSPACE_ROOT}/terraform/environments"

# Verify terraform/environments directory exists
if [[ ! -d "${TERRAFORM_DIR}" ]]; then
  error "Could not find terraform environments directory at: ${TERRAFORM_DIR}"
  exit 1
fi

# Order of destruction:
# We destroy developer, staging, and production environments first (each kubernetes -> compute -> network)
# and finally the shared transit network and inspection VPC (compute -> network).
targets=(
  "dev/kubernetes"
  "dev/compute"
  "dev/network"
  "stage/kubernetes"
  "stage/compute"
  "stage/network"
  "prod/kubernetes"
  "prod/compute"
  "prod/network"
  "shared/compute"
  "shared/network"
)

# Confirmation prompt
if [[ "${AUTO_APPROVE}" != true && "${DRY_RUN}" != true ]]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}  WARNING: YOU ARE ABOUT TO DESTROY ALL INFRASTRUCTURE IN THIS PROJECT!  ${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "The following environments and layers will be destroyed sequentially:"
  for target in "${targets[@]}"; do
    echo "  • terraform/environments/${target}"
  done
  echo ""
  read -p "Are you absolutely sure you want to proceed? (yes/NO): " CONFIRM
  if [[ "${CONFIRM}" != "yes" ]]; then
    info "Destruction cancelled."
    exit 0
  fi
fi

if [[ "${DRY_RUN}" == true ]]; then
  info "DRY RUN: The following commands would be executed in sequence:"
  echo ""
fi

# Start the destruction process
START_TIME=$(date +%s)

for target in "${targets[@]}"; do
  target_path="${TERRAFORM_DIR}/${target}"
  
  if [[ ! -d "${target_path}" ]]; then
    warn "Directory does not exist, skipping: ${target_path}"
    continue
  fi

  echo ""
  echo "=========================================================================="
  info "Destroying layer: ${target}"
  echo "=========================================================================="
  
  if [[ "${DRY_RUN}" == true ]]; then
    echo "  cd ${target_path}"
    echo "  terraform init"
    echo "  terraform destroy -auto-approve"
  else
    (
      cd "${target_path}"
      info "Initializing Terraform in ${target}..."
      terraform init -input=false
      
      info "Running Terraform Destroy..."
      terraform destroy -auto-approve
    )
    success "Successfully destroyed ${target}."
  fi
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "${DRY_RUN}" == true ]]; then
  success "Dry run check complete!"
else
  success "All Terraform infrastructure destroyed successfully in ${DURATION}s!"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
