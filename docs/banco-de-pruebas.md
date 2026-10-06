# Banco de pruebas de la app (Flutter)

Registro de la corrida del banco de pruebas manual en emulador Android. El **manual de usuario** con las capturas insertadas vive en Notion: [Manual de usuario](https://app.notion.com/p/3f11ebd3a80481fe9f8ef44a5e759a41) (Inicio → Proyectos Personales → Manual de usuario).

- Fecha: 2026-10-05/06. App: Flutter 3.47.6. Emulador: `Testing_Phone`, Android 15 (API 35).
- Backend: `node dist/main` contra un Mongo **local** de pruebas (`mongodb://127.0.0.1:27018/dulceria_test`, réplica de un nodo). Nunca Atlas.
- Datos: `backend/scripts/productos-manual.json` (cargado con `npm run seed -- productos-manual.json`):

| Producto | Costo | Venta | Existencias |
|---|---|---|---|
| Paleta de caramelo | $2.50 | $5.00 | 40 |
| Gomitas de ositos | $12.00 | $20.00 | 3 |
| Chocolate de leche | $8.50 | $15.00 | 1 |
| Chicle de menta | $0.80 | $2.00 | 0 |

- Capturas originales (1080×2400): `docs/capturas/manual/<ID>-<NN>-<paso>.png` (64 archivos).
- Los casos A–E se ejecutaron en orden sobre esos datos; F1 (día completo) empezó con la base reiniciada y los mismos 4 productos.

## Resultados: 20 ✅ / 2 ❌

| Caso | Prueba | Resultado | Observaciones |
|---|---|---|---|
| A1 | Abrir la app | ✅ | Abre en «Hoy». |
| A2 | Moverse entre pestañas | ✅ | |
| B1 | Lista de productos | ✅ | |
| B2 | Agregar producto + validaciones | ❌ | `-5` se guarda como 5 (el `-` se descarta al teclear). Letras bloqueadas y `1.2.3` rechazado: correcto. Alta con 0 existencias: correcto. |
| B3 | Recibir mercancía | ❌ | `0` rechazado (correcto). `2.5` → 25 y `-3` → 3, sin aviso. Costo pre-llenado y recepción válida (20 pzas a $4.50): correcto. |
| B4 | Editar | ✅ | Existencias intactas. |
| B5 | Descontinuar (cancelar/confirmar) | ✅ | |
| B6 | Ver descontinuados | ✅ | |
| C1 | Catálogo y agotados | ✅ | Tocar un agotado no da ningún mensaje. |
| C2 | Carrito: agregar, +, −, quitar | ✅ | |
| C3 | Pasar de las existencias | ✅ | |
| C4 | Carrito vacío | ✅ | |
| C5 | Cobrar un producto | ✅ | |
| C6 | Cobrar varios productos | ✅ | |
| C7 | Existencias insuficientes (venta externa por API) | ✅ | Mensaje del backend, carrito conservado, catálogo recargado. |
| D1 | Hoy sin ventas | ✅ | |
| D2 | Hoy tras varias ventas | ✅ | Esperado a mano: $65.00 / $28.50 / 3; pantalla y API coinciden. |
| D3 | Pocas existencias | ✅ | |
| D4 | Hoy se actualiza solo | ✅ | |
| E1 | Sin servidor: Hoy y Reintentar | ✅ | |
| E2 | Sin servidor: cobrar | ✅ | Tarda ~10 s (tiempo límite). |
| F1 | Día completo | ✅ | Hoy final: $55.00 / $25.00 / 3, coincide con el cálculo a mano y con la API. |

## Hallazgos (no corregidos; solo documentados)

1. **Alta — B3:** en la cantidad, `digitsOnly` borra el `.` y el `-` al teclear, así que `2.5` se convierte en `25` y se registran 25 piezas. Debería rechazarse con mensaje, no transformarse.
2. **Media — B2:** `FilteringTextInputFormatter.allow([0-9.,])` descarta el `-`; `-5` queda como `5` y se guarda un precio positivo.
3. **Baja — C1:** sin mensaje al tocar un producto agotado.
4. **Baja — E2:** el aviso de sin conexión tarda ~10 s (`kApiTimeout`).
5. **Cosmético — F1:** la insignia de cantidad en la tarjeta de producto queda pegada a nombres largos («Chicle de menta»).
