# Documentación del Sistema de Pagos

Esta carpeta contiene toda la documentación relacionada con el sistema de pagos para pedidos.

## 📚 Documentos

1. **[order-payments-system.md](./order-payments-system.md)**
   - Documentación técnica completa del sistema
   - Arquitectura y componentes
   - Modelos de datos
   - API GraphQL
   - Cálculo de montos y comisiones

2. **[payment-flow-explained.md](./payment-flow-explained.md)**
   - Explicación visual del flujo de pago
   - Diagramas paso a paso
   - Flujos por método de pago
   - Pantallas del frontend
   - Código de ejemplo

3. **[frontend-integration-checklist.md](./frontend-integration-checklist.md)**
   - Guía paso a paso para integrar en el frontend
   - Flujos por método de pago (Wallet, Stripe, Transferencia, Efectivo)
   - Pantallas necesarias
   - Configuración de SDKs
   - Checklist de implementación

4. **[backend-pending-fixes.md](./backend-pending-fixes.md)**
   - Ajustes pendientes en el backend
   - Mejoras opcionales
   - Checklist de testing

## 🚀 Inicio Rápido

### Para Backend
1. La migración se ejecuta automáticamente al levantar el servidor
2. Configurar variables de entorno de Stripe
3. Leer `backend-pending-fixes.md` para ajustes opcionales

### Para Frontend
1. Leer `payment-flow-explained.md` para entender el flujo
2. Seguir `frontend-integration-checklist.md` paso a paso
3. Empezar con Fase 1 (Wallet + Stripe)

## 🔗 Enlaces Útiles

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe React Native SDK](https://github.com/stripe/stripe-react-native)
- [GraphQL Playground](http://localhost:8000/graphql)

---

**Última actualización:** Enero 2026
