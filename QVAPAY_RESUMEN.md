# QvaPay - Implementación Completada

## ✅ Flujo Implementado

1. Usuario selecciona QvaPay en checkout
2. Se crea la orden con `paymentMethod: "qvapay"` → estado `pending_payment`
3. Se cierra el carrito y se muestra la orden en el detalle
4. En el detalle de la orden, aparece botón "Pagar" (cuando la orden esté aceptada)
5. Al hacer clic en "Pagar":
   - Se llama a `initiateQvapayPayment` mutation
   - Se abre Safari con la URL de pago de QvaPay
   - Inicia polling automático cada 3 segundos
6. En la sección de pago se muestra "Verificando..." con un spinner pequeño
7. Cuando el pago se completa, se muestra alerta de éxito
8. Si hay timeout (2 minutos), se muestra alerta informativa

## 📁 Archivos Modificados

### Nuevos
- `graphql/payments/InitiateQvapayPayment.graphql` - Mutation GraphQL
- `LlegoiOS/ui/sheets/Cart/QvaPayRepository.swift` - Repository para QvaPay
- `LlegoiOS/GraphQL/Operations/Mutations/InitiateQvapayPaymentMutation.graphql.swift` - Generado por Apollo

### Modificados
- `LlegoiOS/ui/sheets/Cart/CartView.swift` - Simplificado, solo crea orden
- `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` - Agregado soporte QvaPay y polling
- `LlegoiOS/ui/screens/Order/Detail/OrderDetailView.swift` - Agregado indicador "Verificando..." 
- `LlegoiOS/ui/screens/Order/Detail/OrderDetailRepository.swift` - Agregado `fetchOrderAsync`
- `schema.graphqls` - Actualizado desde backend

## 🎯 Características

✅ QvaPay aparece solo si el branch lo acepta (controlado por backend)
✅ Orden se crea con estado `pending_payment`
✅ Pago se realiza desde el detalle de la orden (igual que otros métodos)
✅ Polling discreto en la UI (spinner pequeño + "Verificando...")
✅ Polling automático cada 3 segundos (máximo 2 minutos)
✅ Detección automática de pago completado
✅ Alertas de éxito/error/timeout
✅ Limpieza automática del polling al salir

## 🧪 Testing

1. Agregar productos al carrito
2. Seleccionar QvaPay (solo aparece si el branch lo acepta)
3. Hacer checkout → se crea la orden
4. Ir al detalle de la orden
5. Hacer clic en "Pagar" → se abre Safari
6. Completar pago en QvaPay
7. Volver a la app → ver "Verificando..." en la sección de pago
8. Esperar a que se detecte el pago completado

## 📝 Notas

- El método QvaPay debe estar configurado en el backend
- El webhook de QvaPay debe actualizar `paymentStatus` a "completed"
- La imagen "qvapay" ya existe en Assets.xcassets
- El polling se limpia automáticamente al salir de la vista
