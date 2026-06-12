# Problemas a Corregir — LlegoiOS

Revisión general del proyecto. Ordenados por severidad.

---

## 🔴 Críticos

### 1. Stripe cobra pero el saldo no se acredita si falla el backend
**Archivo:** `LlegoiOS/ui/screens/Wallet/WalletViewModel.swift` ~línea 308  
**Problema:** Stripe captura el pago primero y después se llama `depositMoney` en el backend. Si esa segunda llamada falla (red caída, error 500), el `catch` solo muestra un toast genérico y sigue. El usuario pierde dinero real sin que su billetera se actualice.  
**Fix:** Usar un webhook server-side para acreditar el saldo (nunca confiar solo en el cliente), o al menos guardar el `paymentIntentId` localmente y ofrecer retry explícito con ese mismo ID.

---

### 2. Confirmación de transferencia siempre muestra éxito aunque falle la API
**Archivo:** `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` ~línea 739  
**Problema:** Si `confirmPaymentSent` lanza cualquier error (401, 500, sin red), el `catch` establece `transferPaymentConfirmed = true` y muestra "Tu pago fue registrado. El negocio lo revisará en breve." El negocio nunca recibe la confirmación.  
**Fix:** En el `catch`, mostrar un error real al usuario y NO marcar la transferencia como confirmada.

---

### 3. Guard invertido — el método de pago equivocado se usa en la segunda orden
**Archivo:** `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` ~línea 346  
**Problema:** La condición en `loadPaymentMethodIfNeeded` está invertida: retorna temprano cuando los códigos NO coinciden (justo cuando habría que recargar). Si el usuario navega a un segundo pedido con diferente método de pago, reutiliza el método anterior.  
**Fix:** Invertir la condición del guard.

---

### 4. Nil-guard de `attemptId` es código muerto — registra éxito sin llamar a la API
**Archivo:** `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` ~línea 700  
**Problema:** El guard que verifica `activePaymentAttemptId == nil` está colocado DESPUÉS de los bloques if/else que necesitan ese ID. Si el ID es nil, ninguna llamada se hace pero el flujo continúa hacia un "éxito" falso, mostrando que el pago fue confirmado.  
**Fix:** Mover el guard al inicio de la función, antes de cualquier llamada.

---

### 5. Fallo de biometría — cero feedback al usuario
**Archivo:** `LlegoiOS/ui/sheets/Cart/CartView.swift` ~línea 590  
**Problema:** Cuando Face ID / Touch ID falla o el usuario cancela, el `else` solo hace `print`. No hay alerta, no hay toast. Si `isLoadingPayment` fue activado antes, el spinner gira para siempre.  
**Fix:** En el `else`, resetear `isLoadingPayment = false` y mostrar una alerta con el motivo del fallo.

---

### 6. WebSocket se cuelga forever si el servidor no envía `connection_ack`
**Archivo:** `LlegoiOS/ui/screens/ConversationalSearch/ConversationalSearchRepository.swift` ~línea 203  
**Problema:** El loop `while !gotAck` llama a `webSocket.receive()` sin timeout ni `Task.isCancelled`. Si el servidor falla o responde de forma inesperada, la UI del chat queda colgada indefinidamente.  
**Fix:** Añadir un timeout (ej. 10s) y verificar `Task.isCancelled` en cada iteración.

---

### 7. Saldo en HomeView es un placeholder hardcodeado `"$3.99"`
**Archivo:** `LlegoiOS/ui/screens/Home/HomeView.swift` ~línea 55  
**Problema:** Todos los usuarios siempre ven `$3.99` como saldo en pantalla principal, independientemente de su balance real.  
**Fix:** Cargar el balance real desde `MyWalletBalanceQuery` al aparecer la pantalla.

---

## 🟠 Altos

### 8. JWT completo se imprime en consola en cada aparición de HomeView
**Archivo:** `LlegoiOS/ui/screens/Home/HomeView.swift` ~línea 492  
**Problema:** En producción, cualquier desarrollador o tester con Xcode / Console.app conectado puede copiar el token y autenticarse como el usuario contra el backend.  
**Fix:** Eliminar el `print` del token, o envolverlo en `#if DEBUG`.

---

### 9. ProfileView muestra datos inventados a todos los usuarios
**Archivo:** `LlegoiOS/ui/screens/Profile/ProfileView.swift` ~línea 31  
**Problema:** Nivel "Cliente Oro", 847 puntos, saldo "$120.50" — son constantes hardcodeadas. Un usuario nuevo ve información completamente falsa sobre su cuenta.  
**Fix:** Reemplazar con datos cargados desde el backend (query `Me` o equivalente).

---

### 10. En iOS 26, ProfileView desaparece completamente del TabView
**Archivo:** `LlegoiOS/ContentView.swift` ~línea 127  
**Problema:** El tab de Perfil solo existe en la rama `#else` (iOS < 26). Los usuarios en iOS 26 no tienen ninguna ruta persistente al perfil, historial de pedidos ni configuración de cuenta.  
**Fix:** Añadir ProfileView como tab también en la rama de iOS 26.

---

### 11. Doble orden posible en ventana de 200ms tras seleccionar dirección
**Archivo:** `LlegoiOS/ui/sheets/Cart/CartView.swift` ~línea 196  
**Problema:** `pendingPaymentAfterAddressSelection` dispara `processPayment()` con `asyncAfter(0.2s)` sin deshabilitar el botón de pago. Si el usuario toca "Pedir" durante esos 200ms, se crean dos órdenes.  
**Fix:** Deshabilitar el botón de pago mientras `pendingPaymentAfterAddressSelection == true`, o añadir un guard contra `isLoadingPayment` al inicio de `processPayment`.

---

### 12. Polling de TransferMóvil sin límite máximo — spinner infinito
**Archivo:** `LlegoiOS/ui/sheets/Cart/CartViewModel.swift` ~línea 1025  
**Problema:** `startShortcutPolling` corre indefinidamente si el backend nunca devuelve un estado terminal. El usuario queda atrapado en el spinner sin poder reintentar ni cancelar.  
**Fix:** Añadir un límite de iteraciones (ej. 60 intentos = 5 min) y mostrar un mensaje de timeout con opción de reintentar manualmente.

---

### 13. Polling de QvaPay silencia todos los errores durante 2 minutos
**Archivo:** `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` ~línea 484  
**Problema:** Cada error de `fetchOrderAsync` se captura con un `print`. Si el usuario pierde la red justo después de ser redirigido a QvaPay, los 40 intentos fallan en silencio durante 2 minutos antes de mostrar un mensaje vago.  
**Fix:** Detectar errores de red vs. errores de auth, mostrar indicador de "sin conexión" en tiempo real, y hacer early-exit en errores 401 repetidos.

---

### 14. Flujo de chat: `isTyping` nunca se resetea si stream falla y fallback también es cancelado
**Archivo:** `LlegoiOS/ui/screens/ConversationalSearch/ConversationalSearchRepository.swift` ~línea 68  
**Problema:** Si el stream lanza un error no-cancellation y el fallback HTTP también es cancelado (porque llegó un nuevo mensaje), el `completion` nunca se llama. El ViewModel queda con `isTyping = true` para siempre.  
**Fix:** Garantizar que `completion` siempre se llama en todos los caminos de salida, incluyendo `CancellationError` en el fallback.

---

### 15. Hydration de entidades continúa ejecutándose tras cancelación de mensaje
**Archivo:** `LlegoiOS/ui/screens/ConversationalSearch/ConversationalSearchRepository.swift` ~línea 301  
**Problema:** Tras completar el stream, se lanzan calls HTTP de hydration sin `Task.isCancelled`. Si el usuario envía un nuevo mensaje, el `activeBackendTask` es cancelado pero las hydration tasks siguen corriendo y consumiendo red.  
**Fix:** Verificar `Task.isCancelled` antes de iniciar la hydration, o incluirlas dentro del mismo `Task` cancelable.

---

### 16. Spinner de pull-to-refresh desaparece tras 0.5s fijos, no al completar la carga
**Archivo:** `LlegoiOS/ui/screens/Feed/ProductFeedView.swift` ~línea 476  
**Problema:** El spinner se oculta después de un `asyncAfter(0.5s)` aunque el fetch tarde 3–5 segundos. El contenido actualiza de golpe sin aviso visual, y en conexiones lentas el usuario puede tocar items del feed anterior.  
**Fix:** Esperar a que el `ViewModel` complete la carga antes de resolver la continuación.

---

## 🟡 Medios

### 17. Múltiples Tasks en paralelo escriben sobre `cashKycStatusSnapshot`
**Archivo:** `LlegoiOS/ui/sheets/Cart/CartView.swift` ~línea 788  
**Problema:** `refreshCashKycStatusBanner` no cancela la task anterior antes de lanzar una nueva. Si el usuario cambia de método de pago rápidamente, varias tasks compiten y la última en terminar (no la última en iniciar) gana.  
**Fix:** Guardar la task anterior y cancelarla antes de crear una nueva.

---

### 18. `ProfileView` usa `LottieView` para estado de carga, violando las reglas del proyecto
**Archivo:** `LlegoiOS/ui/screens/Profile/ProfileView.swift` ~línea 327  
**Problema:** El CLAUDE.md prohíbe explícitamente usar `LottieView` para loading. Además, si el archivo Lottie no existe en el bundle, la pantalla de carga aparece completamente en blanco.  
**Fix:** Reemplazar con `ProgressView` nativo.

---

### 19. TronDealer polling no se cancela si el usuario hace pop de la pantalla
**Archivo:** `LlegoiOS/ui/screens/Order/Detail/OrderDetailViewModel.swift` ~línea 575  
**Problema:** `stopTronDealerPolling` solo se llama desde el `onDismiss` del sheet. Si el usuario navega hacia atrás mientras el sheet está abierto, la task sigue corriendo hasta 30 minutos haciendo requests innecesarios.  
**Fix:** Llamar `stopTronDealerPolling` también en `onDisappear` de la vista.

---

### 20. `DispatchQueue.main.asyncAfter` del mensaje de bienvenida puede dispararse tras cerrar la pantalla
**Archivo:** `LlegoiOS/ui/screens/ConversationalSearch/ConversationalSearchView.swift` ~línea 148  
**Problema:** Si el usuario abre y cierra el chat en menos de 400ms, el closure retiene el `viewModel` y llama `sendWelcomeMessage` sobre una vista ya descartada.  
**Fix:** Usar `Task { try await Task.sleep(...) }` con verificación de `Task.isCancelled`, cancelándolo en `onDisappear`.

---

*Generado: Junio 2026*
