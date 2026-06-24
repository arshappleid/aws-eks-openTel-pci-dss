#!/usr/bin/env bash



set -euo pipefail

BUCKET="prab-terraform-backend"
REGION="us-east-1"

echo "Scanning for local terraform.tfstate files inside /terraform..."


find /terraform -name "terraform.tfstate" -not -path "*/.terraform/*" | while read -r state_file; do
    dir=$(dirname "$state_file")
    echo ""
    echo "=========================================================="
    echo "Migrating state in: $dir"
    echo "=========================================================="

    (
        cd "$dir"

        terraform init -migrate-state -force-copy \
          -backend-config="bucket=$BUCKET" \
          -backend-config="region=$REGION"
    )
done

echo ""
echo "Migration complete!"