#!/bin/sh

# Genera Secrets.swift con la Stripe publishable key inyectada desde
# la variable de entorno de Xcode Cloud (configurada como Secret en el workflow).
# El archivo está en .gitignore y nunca se commitea.

cat > "$CI_WORKSPACE/LlegoiOS/network/Secrets.swift" <<EOF
import Foundation

struct StripeSecrets {
    static let publishableKey = "${STRIPE_PUBLISHABLE_KEY}"
}
EOF

echo "Secrets.swift generado correctamente."
