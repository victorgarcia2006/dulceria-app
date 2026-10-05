# Dulcería POS

App de punto de venta para una dulcería pequeña. Monorepo:

- `backend/` — API NestJS (activo)
- `app/` — Flutter (futuro)
- `docs/` — documentación (contrato de API en `docs/api-contract.md`)

## Alcance (CONGELADO)
Solo: (1) registrar compras que suman al inventario, (2) vender descontando inventario y calculando ganancia, (3) descontinuar productos sin perder historial.

Fuera de alcance, NO implementar: venta a granel, fiado, tickets/PDF, código de barras, multiusuario, auth, reportes avanzados.

## Stack
NestJS + TypeScript + MongoDB (Mongoose) + class-validator/class-transformer. Sin auth. Comentarios y mensajes de error en español.

## Reglas de negocio
- El costo de una venta es el `costPrice` ACTUAL del producto al vender, congelado en la venta (`unitCostAtSale`). Sin promedio ponderado ni FIFO. Compras futuras no alteran ventas pasadas.
- Descontinuar oculta el producto del catálogo de venta pero conserva el historial (el nombre queda copiado en cada venta).
- Nunca se puede vender más de lo que hay en stock.
- El stock NUNCA se edita desde `PATCH /products/:id`; solo cambia con compras (suma) y ventas (resta).
- Una compra (transacción): crea la compra, suma stock y actualiza `costPrice` del producto a `unitCost`.
- Una venta es todo o nada: si un item no alcanza, no se modifica nada (422). Inexistente → 404. Descontinuado → 422.
- "Hoy" se calcula en zona horaria America/Mexico_City, no UTC.

## Convenciones
- Prefijo global `/api`, puerto 3000, escucha en 0.0.0.0, CORS habilitado.
- Productos se devuelven con `id` (string), sin `_id`.
- Conexión a Mongo por `MONGODB_URI` (`backend/.env`, nunca commitear).
- Un commit por paso con mensaje descriptivo.

## Comandos (desde `backend/`)
- `npm install` — dependencias. Crear `backend/.env` a partir de `.env.example` (`MONGODB_URI`; `DNS_SERVERS=8.8.8.8,1.1.1.1` si falla `querySrv ECONNREFUSED`).
- `npm run build` — compila a `dist/`. `npm run start:dev` (watch) / `npm run start:prod` — servidor en :3000.
- `npm run e2e` — pruebas contra la API real (servidor corriendo); limpia lo que crea.
- `npm run seed [-- archivo.json]` — carga `scripts/productos-reales.json` vía API.
- TypeScript fijado en ^6: el CLI de Nest y ts-node no funcionan con TS 7.
- Contrato de la API: `docs/api-contract.md`.
