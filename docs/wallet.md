Resumen de Novedades de Wallet para Frontend
1. Campos de Wallet en GraphQL
Tanto User como Branch ahora tienen campos de wallet disponibles:


type UserType {
  # ... otros campos
  wallet: WalletBalanceType!      # Balance de la wallet
  walletStatus: String!            # Estado: "active", "frozen", "closed"
}

type BranchType {
  # ... otros campos  
  wallet: WalletBalanceType!      # Balance de la wallet
  walletStatus: String!            # Estado: "active", "frozen", "closed"
}

type WalletBalanceType {
  local: Float!   # Balance en moneda local
  usd: Float!     # Balance en USD
}
Comportamiento importante: Si el wallet no existe en la BD, retorna {local: 0.0, usd: 0.0} y status "active" por defecto.

2. Queries Disponibles

# Para usuarios (requiere JWT)
query {
  myWallet(jwt: String!): WalletStatusType
  myWalletTransactions(
    jwt: String!
    limit: Int = 50
    skip: Int = 0
    currency: String  # "local" o "usd"
  ): [WalletTransactionType!]!
}

# Para sucursales (solo managers o dueños)
query {
  branchWallet(branchId: String!, jwt: String!): WalletStatusType
  branchWalletTransactions(
    branchId: String!
    jwt: String!
    limit: Int = 50
    skip: Int = 0
    currency: String
  ): [WalletTransactionType!]!
}
3. Mutations Disponibles

mutation {
  # Transferir dinero desde usuario
  transferMoney(
    jwt: String!
    input: {
      toOwnerId: String!
      toOwnerType: String!  # "user" o "branch"
      amount: Float!
      currency: String!      # "local" o "usd"
      description: String
    }
  ): WalletTransactionType!
  
  # Depositar dinero
  depositMoney(
    jwt: String!
    input: {
      amount: Float!
      currency: String!
      source: String!        # "bank_transfer", "credit_card", etc.
      description: String
    }
  ): WalletTransactionType!
  
  # Retirar dinero
  withdrawMoney(
    jwt: String!
    input: {
      amount: Float!
      currency: String!
      destination: String!   # Cuenta bancaria, tarjeta, etc.
      description: String
    }
  ): WalletTransactionType!
  
  # Transferir desde sucursal (solo managers/dueños)
  branchTransferMoney(
    branchId: String!
    jwt: String!
    input: TransferInput!
  ): WalletTransactionType!
  
  # Retirar desde sucursal (solo managers/dueños)
  branchWithdrawMoney(
    branchId: String!
    jwt: String!
    input: WithdrawInput!
  ): WalletTransactionType!
}
Planificación de la Colección wallet_transactions
Estructura Actual de la Colección
Ya está implementada con esta estructura:


{
  _id: String (UUID),
  fromOwnerId: String | null,      // null para depósitos externos
  fromOwnerType: "user" | "branch" | null,
  toOwnerId: String | null,        // null para retiros
  toOwnerType: "user" | "branch" | null,
  amount: Float,
  currency: "local" | "usd",
  type: "transfer" | "deposit" | "withdrawal",
  status: "pending" | "completed" | "failed" | "reversed",
  description: String | null,
  metadata: Object | null,         // Info adicional (order_id, payment_gateway_id, etc)
  createdAt: DateTime,
  completedAt: DateTime | null
}
Tipos de Transacciones
1. Transfer (Usuario → Usuario/Sucursal)

{
  fromOwnerId: "user_123",
  fromOwnerType: "user",
  toOwnerId: "branch_456",
  toOwnerType: "branch",
  type: "transfer",
  status: "completed",
  amount: 50.00,
  currency: "usd"
}
2. Deposit (Externo → Usuario/Sucursal)

{
  fromOwnerId: null,
  fromOwnerType: null,
  toOwnerId: "user_123",
  toOwnerType: "user",
  type: "deposit",
  status: "completed",
  amount: 100.00,
  currency: "local",
  metadata: {
    source: "bank_transfer",
    paymentGatewayId: "stripe_xyz"
  }
}
3. Withdrawal (Usuario/Sucursal → Externo)

{
  fromOwnerId: "user_123",
  fromOwnerType: "user",
  toOwnerId: null,
  toOwnerType: null,
  type: "withdrawal",
  status: "pending",  // Requiere aprobación manual
  amount: 75.00,
  currency: "usd",
  metadata: {
    destination: "bank_account_123",
    bankName: "Banco Nacional"
  }
}
Índices Recomendados para MongoDB

// Para queries de historial por usuario
db.wallet_transactions.createIndex({ "fromOwnerId": 1, "createdAt": -1 })
db.wallet_transactions.createIndex({ "toOwnerId": 1, "createdAt": -1 })

// Para queries combinadas (owner + currency)
db.wallet_transactions.createIndex({ 
  "fromOwnerId": 1, 
  "currency": 1, 
  "createdAt": -1 
})
db.wallet_transactions.createIndex({ 
  "toOwnerId": 1, 
  "currency": 1, 
  "createdAt": -1 
})

// Para admin queries por status
db.wallet_transactions.createIndex({ "status": 1, "createdAt": -1 })
Flujo de Transacciones
Atomicidad con MongoDB Transactions

# El código ya usa MongoDB transactions para garantizar atomicidad:
async with await db.client.start_session() as session:
    async with session.start_transaction():
        # 1. Deducir del sender
        # 2. Agregar al receiver  
        # 3. Crear registro de transacción
        # Si cualquier paso falla, rollback automático
Estados de Transacciones
Estado	Descripción	Uso
pending	Esperando confirmación	Retiros que requieren aprobación manual
completed	Completada exitosamente	Transferencias y depósitos exitosos
failed	Falló por algún error	Saldo insuficiente, wallet inactiva, etc
reversed	Revertida/cancelada	Para reversiones administrativas
Casos de Uso para el Frontend
1. Mostrar Balance

query GetMyWallet {
  me(jwt: $jwt) {
    wallet {
      local
      usd
    }
    walletStatus
  }
}
2. Historial de Transacciones

query GetTransactions($jwt: String!, $limit: Int, $currency: String) {
  myWalletTransactions(jwt: $jwt, limit: $limit, currency: $currency) {
    id
    fromOwnerId
    toOwnerId
    amount
    currency
    type
    status
    description
    createdAt
  }
}
3. Realizar Pago a Sucursal

mutation PayToBranch($jwt: String!, $branchId: String!, $amount: Float!) {
  transferMoney(
    jwt: $jwt
    input: {
      toOwnerId: $branchId
      toOwnerType: "branch"
      amount: $amount
      currency: "local"
      description: "Pago por pedido"
    }
  ) {
    id
    status
    amount
  }
}
Recomendaciones para el Frontend
Mostrar transacciones con iconos según tipo:

transfer + fromOwnerId == currentUser: 🔴 Salida (rojo)
transfer + toOwnerId == currentUser: 🟢 Entrada (verde)
deposit: 🟢 Depósito
withdrawal: 🔴 Retiro
Polling o WebSocket para actualizar balance en tiempo real

Validación de montos antes de enviar mutations

Mostrar status de withdrawal como "Pendiente de aprobación"

Implementar confirmación antes de transferencias grandes