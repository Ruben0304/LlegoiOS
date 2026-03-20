# TronDealer (USDT) - Implementación Completada

## ✅ Flujo Implementado

1. Usuario selecciona USDT/TronDealer en checkout
2. Se crea la orden con `paymentMethod: "usdt"` → estado `pending_payment`
3. Se cierra el carrito y se muestra la orden en el detalle
4. En el detalle de la orden, aparece botón "Pagar" (cuando la orden esté aceptada)
5. Al hacer clic en "Pagar":
   - Se llama a `initiateTrondealerPayment` mutation
   - Backend genera wallet address única
   - Se muestra sheet con:
     * QR code de la dirección
     * Dirección copiable
     * Monto exacto en USDT
     * Instrucciones paso a paso
     * Advertencias importantes
   - Inicia polling automático cada 5 segundos
6. Usuario envía USDT desde su wallet (TronLink, Trust Wallet, etc.)
7. Polling detecta confirmación en blockchain (1-2 minutos)
8. Cuando el pago se completa, se muestra alerta de éxito

## 📁 Archivos Creados

- `graphql/payments/InitiateTrondealerPayment.graphql` - Mutation GraphQL
- `LlegoiOS/ui/sheets/Cart/TronDealerRepository.swift` - Repository para TronDealer
- `LlegoiOS/ui/sheets/Cart/TronDealerPaymentView.swift` - Vista con QR, dirección, instrucciones
- `LlegoiOS/GraphQL/Operations/Mutations/InitiateTrondealerPaymentMutation.graphql.swift` - Generado por Apollo

## 📝 Archivos Modificados

- `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` - Agregado soporte TronDealer y polling
- `LlegoiOS/ui/screens/Order/Detail/OrderDetailView.swift` - Agregado sheet y icono
- `LlegoiOS/models/OrderPermissionPolicy.swift` - Agregado "usdt" a métodos permitidos
- `schema.graphqls` - Actualizado desde backend

## 🎯 Características

✅ TronDealer aparece solo si el branch lo acepta (controlado por backend)
✅ Orden se crea con estado `pending_payment`
✅ Pago se realiza desde el detalle de la orden
✅ Sheet nativo con QR code generado en la app
✅ Dirección copiable con feedback háptico
✅ Instrucciones claras paso a paso
✅ Advertencias sobre red correcta (TRC20)
✅ Polling cada 5 segundos (máximo 30 minutos)
✅ Detección automática de confirmación en blockchain
✅ Alertas de éxito/error/timeout
✅ Limpieza automática del polling al cerrar

## 🔄 Diferencias con QvaPay

| Aspecto | QvaPay | TronDealer |
|---------|---------|------------|
| **Inicio** | Abre Safari con URL | Muestra sheet con QR |
| **Pago** | Dentro de QvaPay | Desde wallet externa |
| **Confirmación** | Instantánea | 1-2 minutos (blockchain) |
| **Polling** | 3 segundos, 2 min max | 5 segundos, 30 min max |
| **UI** | Solo polling | QR + dirección + instrucciones |

## 🧪 Testing

1. Agregar productos al carrito
2. Seleccionar USDT/TronDealer (solo aparece si el branch lo acepta)
3. Hacer checkout → se crea la orden
4. Ir al detalle de la orden
5. Hacer clic en "Pagar" → se abre sheet
6. Copiar dirección o escanear QR
7. Enviar USDT desde wallet (TronLink, Trust Wallet)
8. Ver "Esperando confirmación..." en el sheet
9. Esperar confirmación en blockchain (1-2 minutos)
10. Ver alerta de éxito

## ⚠️ Advertencias Mostradas

- ⚠️ Asegúrate de usar la red TRON (TRC20)
- ⚠️ No envíes desde exchanges (usa wallet personal)
- ⚠️ Envía el monto exacto mostrado arriba

## 📝 Notas

- El método USDT debe estar configurado en el backend
- El webhook de TronDealer debe actualizar `paymentStatus` a "completed"
- El polling se limpia automáticamente al cerrar la vista
- Timeout de 30 minutos (suficiente para confirmaciones blockchain)
- QR code generado nativamente con CoreImage
