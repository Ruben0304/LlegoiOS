#!/bin/sh

# Deriva la raíz del repo desde la ubicación de este script (ci_scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cat > "$REPO_ROOT/LlegoiOS/network/Secrets.swift" <<EOF
import Foundation

struct StripeSecrets {
    static let publishableKey = "${STRIPE_PUBLISHABLE_KEY}"
}
EOF

echo "Secrets.swift generado en $REPO_ROOT/LlegoiOS/network/Secrets.swift"
