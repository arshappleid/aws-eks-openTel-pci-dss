#!/usr/bin/env bash
# ==============================================================================
# migrate_state.sh — Non-interactively migrates local tfstate files to S3
# ==============================================================================
set -euo pipefail

BUCKET="prab-terraform-backend"
REGION="us-east-1"

echo "Scanning for local terraform.tfstate files inside /terraform..."

# Find all directories containing terraform.tfstate (ignoring internal .terraform directories)
find /terraform -name "terraform.tfstate" -not -path "*/.terraform/*" | while read -r state_file; do
    dir=$(dirname "$state_file")
    echo ""
    echo "=========================================================="
    echo "Migrating state in: $dir"
    echo "=========================================================="
    
    (
        cd "$dir"
        # Run init with migrate-state and force-copy to execute non-interactively
        terraform init -migrate-state -force-copy \
          -backend-config="bucket=$BUCKET" \
          -backend-config="region=$REGION"
    )
done

echo ""
echo "Migration complete!"
