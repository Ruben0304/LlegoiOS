# Cash KYC Test Checklist (iOS)

## Unit tests recomendados

1. La sección de Perfil no renderiza campos de entrada para `merchantId/branchId`.
2. El contexto de merchant se resuelve internamente desde selección visual de negocio/sucursal.

1. `CashKycEvalStatus` mapping:
- `not_required`, `pending_evidence`, `submitted`, `approved`, `rejected`, `needs_review`, `insufficient_data`, `error`, `expired`
- valor desconocido -> `unknown(...)`

2. `CashCoverageStatus` mapping:
- `eligible_covered`, `eligible_uncovered`, `blocked`
- valor desconocido -> `unknown(...)`

3. Resolución de flags backend:
- `allowCash` explícito true/false
- fallback por `cashCoverageStatus`

4. `nextAction` y estado UI:
- `pending_evidence` -> captura
- `submitted` -> espera/polling
- `rejected` -> bloqueo
- `needs_review`, `insufficient_data`, `error` -> retryable
- `expired` -> recaptura

5. Tolerancia a respuestas parciales:
- campos opcionales ausentes
- `reasonCodes` ausente
- `correlationId` ausente

## Integración / feature tests recomendados

1. Perfil account-level: `cashKycPolicyByMerchant` + `cashKycStatusByAccount`.
2. Perfil account-level: `startCashKycEvaluationByAccount` con merchantId y branchId opcional.
3. Perfil account-level: `submitted` -> polling -> `approved/rejected`.
4. Perfil account-level: `expired/insufficient_data/error` permite nueva evidencia.
5. Perfil account-level: `RETRY_NOT_SUPPORTED_FOR_ACCOUNT_VERIFICATION` muestra fallback UX seguro.

## Checkout / reusable por merchant

1. Checkout cash con reusable approved por merchant -> no pide evidencia.
2. Checkout cash sin reusable -> cae al flujo checkout-level actual con `paymentAttemptId`.
3. Checkout cash con `not_required`/uncovered -> permite continuar y muestra mensaje.
4. Checkout cash con error account-level -> fallback al flujo checkout-level sin romper compra.

## Integración / feature tests recomendados (legacy / compatibilidad)

1. KYC off (`allowCash=true`, `appCoversCash=false`) -> efectivo permitido sin cobertura.
2. KYC on + reusable approved -> efectivo permitido.
3. KYC on + pending evidence -> requiere captura.
4. Submit -> `submitted` -> polling hasta `approved`.
5. Submit -> `rejected` -> bloquear efectivo.
6. Submit -> `needs_review`/`insufficient_data` -> retry.
7. Submit -> `error` -> retry o cambio de método.
8. `expired` -> solicitar nueva evidencia.
9. Cambio a otro método desde bloqueo de KYC.
10. Regresión no-cash (wallet/transfer/qvapay/usdt) sin cambios de comportamiento.

## UI tests recomendados

1. Captura documento.
2. Captura selfie sosteniendo carnet.
3. Envío habilitado solo con ambas evidencias.
4. Perfil no muestra campos técnicos de IDs.
5. Bloqueo de efectivo cuando backend no permite continuar.
6. Continuación cuando backend aprueba o permite sin cobertura.
