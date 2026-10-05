# Contrato de la API — Dulcería POS

Documento del contrato **tal como quedó implementado** en `backend/`. Los ejemplos de respuesta son salidas reales de la API.

## Generalidades

| Tema | Detalle |
|---|---|
| Base URL | `http://<host>:3000/api` (el servidor escucha en `0.0.0.0:3000`) |
| Formato | JSON (`Content-Type: application/json`) en peticiones y respuestas |
| Auth | Ninguna |
| CORS | Habilitado para cualquier origen (Flutter Web puede llamarla directo) |
| IDs | Siempre string de 24 caracteres hex, en el campo `id` (nunca `_id`). Las referencias (`productId`) también son strings |
| Fechas | `createdAt` en ISO 8601 UTC (`2026-10-05T15:09:25.102Z`). Para mostrar al usuario, convertir a hora de Ciudad de México |
| Dinero | Números (pesos, con decimales). Los totales y ganancias se redondean a 2 decimales |
| Validación | Los campos que no están en el contrato se **ignoran** (whitelist), salvo `stock` en `PATCH /products/:id`, que se rechaza con 400 |

### Formato de error

Todos los errores tienen esta forma; `message` es un `string`, o una lista de `string` cuando hay varios errores de validación (400):

```json
{ "message": "No existe un producto con id \"abc\".", "error": "Not Found", "statusCode": 404 }
```

```json
{ "message": ["La cantidad debe ser mayor a 0", "El costo unitario no puede ser negativo"], "error": "Bad Request", "statusCode": 400 }
```

| Código | Cuándo |
|---|---|
| 400 | Validación del body/query (campo faltante, tipo incorrecto, negativo, `stock` en PATCH, fecha inválida) |
| 404 | Producto inexistente o con id mal formado |
| 422 | Regla de negocio de la venta: stock insuficiente o producto descontinuado |

> En el frontend: mostrar `message` directo al usuario en 422 (ya viene redactado para mostrarse). En 400, `message` puede ser lista.

---

## Modelos

### Product
```json
{ "id": "6ac3be1a690eb40b5b02adf9", "name": "Paleta de caramelo", "costPrice": 2.5, "salePrice": 5, "stock": 40, "active": true }
```
| Campo | Tipo | Notas |
|---|---|---|
| `id` | string | |
| `name` | string | Sin espacios en los extremos |
| `costPrice` | number | ≥ 0. Último costo de compra |
| `salePrice` | number | ≥ 0 |
| `stock` | number (entero) | ≥ 0. Solo cambia con compras (+) y ventas (−) |
| `active` | boolean | `false` = descontinuado |

### Purchase
```json
{ "id": "6ac3bd24e2ee53932c004c16", "productId": "6ac3bd23e2ee53932c004c15", "quantity": 20, "unitCost": 2.5, "createdAt": "2026-10-05T15:07:16.411Z" }
```

### Sale
```json
{
  "id": "6ac3bda5690eb40b5b02adf5",
  "items": [
    { "productId": "6ac3bd23e2ee53932c004c15", "name": "Gomita", "quantity": 5, "unitCostAtSale": 2.8, "unitSalePrice": 3, "profit": 1 }
  ],
  "total": 15,
  "totalProfit": 1,
  "createdAt": "2026-10-05T15:09:25.102Z"
}
```
`name`, `unitCostAtSale` y `unitSalePrice` están **congelados** al momento de la venta: cambios posteriores de precio/costo o descontinuar el producto no los alteran.

---

## Products

### `GET /api/products`
Lista productos **activos**, ordenados por nombre.

| Query | Tipo | Descripción |
|---|---|---|
| `includeDiscontinued` | `true` \| `false` | Con `true` devuelve también los descontinuados (`active: false`) |

- **200** → `Product[]` (lista vacía `[]` si no hay)
- **400** → `includeDiscontinued` con otro valor: `{"message":["includeDiscontinued debe ser true o false"],...}`

### `POST /api/products`
Crea un producto.

```json
{ "name": "Paleta", "costPrice": 2.5, "salePrice": 5, "stock": 0 }
```
| Campo | Requerido | Reglas |
|---|---|---|
| `name` | sí | texto no vacío (se recorta) |
| `costPrice` | sí | número ≥ 0 |
| `salePrice` | sí | número ≥ 0 |
| `stock` | no | entero ≥ 0, por defecto 0. Para stock inicial con historial, preferir `POST /purchases` |

- **201** → `Product` (`active: true`)
```json
{ "name": "Paleta Payaso", "costPrice": 2.5, "salePrice": 5, "stock": 0, "active": true, "id": "6ac3bcf096fd53a6716d0fae" }
```
- **400** → ej. `["El precio de costo no puede ser negativo"]`, `["El nombre es obligatorio"]`

### `PATCH /api/products/:id`
Edita `name`, `costPrice` y/o `salePrice` (todos opcionales; los no enviados no cambian).

```json
{ "salePrice": 6, "name": "Paleta" }
```
- **200** → `Product` actualizado
- **400** → valores inválidos, o si el body incluye `stock`:
```json
{ "message": ["El stock no se puede editar aquí; usa compras (suma) o ventas (resta)"], "error": "Bad Request", "statusCode": 400 }
```
- **404** → `id` inexistente o mal formado: `"No existe un producto con id \"abc\"."`

### `PATCH /api/products/:id/discontinue`
Descontinúa el producto (`active: false`). No borra nada; es idempotente (repetirlo no da error). Sin body.

- **200** → `Product` con `active: false`
- **404** → `id` inexistente o mal formado

---

## Purchases

### `POST /api/purchases`
Registra una compra. En **una sola transacción**: crea la compra, suma `quantity` al stock y fija `costPrice` del producto en `unitCost` (la compra más reciente define el costo; no hay promedio). Si algo falla no queda nada a medias. Se puede comprar un producto descontinuado.

```json
{ "productId": "6ac3bd23e2ee53932c004c15", "quantity": 20, "unitCost": 2.5 }
```
| Campo | Requerido | Reglas |
|---|---|---|
| `productId` | sí | id de un producto existente |
| `quantity` | sí | entero ≥ 1 |
| `unitCost` | sí | número ≥ 0 |

- **201** → `{ purchase, product }`, con el producto **ya actualizado**:
```json
{
  "purchase": { "productId": "6ac3bd23e2ee53932c004c15", "quantity": 20, "unitCost": 2.5, "createdAt": "2026-10-05T15:07:16.411Z", "id": "6ac3bd24e2ee53932c004c16" },
  "product": { "name": "Gomita", "costPrice": 2.5, "salePrice": 3, "stock": 20, "active": true, "id": "6ac3bd23e2ee53932c004c15" }
}
```
- **400** → `["La cantidad debe ser mayor a 0", "El costo unitario no puede ser negativo"]`
- **404** → producto inexistente **o `productId` mal formado**: `"No existe un producto con id \"...\"."`

### `GET /api/purchases`
Historial de compras, **más recientes primero**.

| Query | Descripción |
|---|---|
| `productId` | Opcional. Solo compras de ese producto |

- **200** → `Purchase[]`
- **400** → `productId` mal formado: `["productId no es un id válido"]` (en el filtro es 400; en el body de POST es 404)

> `Purchase` no trae el nombre del producto; el frontend lo resuelve con `GET /products?includeDiscontinued=true`.

---

## Sales

### `POST /api/sales`
Registra una venta (carrito). **Todo o nada**, en una transacción:

1. Se cargan los productos y se valida **todo** antes de modificar nada.
2. Si todo es válido, por cada producto se congelan `name`, `costPrice` actual → `unitCostAtSale` y `salePrice` actual → `unitSalePrice`; `profit = (unitSalePrice − unitCostAtSale) × quantity`; se descuenta el stock.
3. `total = Σ(unitSalePrice × quantity)`, `totalProfit = Σ profit`.

Si el mismo `productId` viene repetido, se **agrupa sumando cantidades** (un solo renglón en la venta). Los renglones salen en el orden en que aparece por primera vez cada producto.

```json
{ "items": [ { "productId": "6ac3bd23e2ee53932c004c15", "quantity": 2 }, { "productId": "6ac3bda3690eb40b5b02adf3", "quantity": 3 }, { "productId": "6ac3bd23e2ee53932c004c15", "quantity": 3 } ] }
```
| Campo | Reglas |
|---|---|
| `items` | lista con al menos 1 elemento |
| `items[].productId` | string, id de un producto existente |
| `items[].quantity` | entero ≥ 1 |

- **201** → `Sale` completa (los dos `Gomita` quedaron agrupados en 5):
```json
{
  "items": [
    { "productId": "6ac3bd23e2ee53932c004c15", "name": "Gomita", "quantity": 5, "unitCostAtSale": 2.8, "unitSalePrice": 3, "profit": 1 },
    { "productId": "6ac3bda3690eb40b5b02adf3", "name": "Chicle", "quantity": 3, "unitCostAtSale": 0.1, "unitSalePrice": 0.3, "profit": 0.6 }
  ],
  "total": 15.9,
  "totalProfit": 1.6,
  "createdAt": "2026-10-05T15:09:25.102Z",
  "id": "6ac3bda5690eb40b5b02adf5"
}
```
- **400** → carrito vacío (`["La venta debe tener al menos un producto"]`), cantidad no entera o ≤ 0 (`["items.0.La cantidad debe ser un número entero"]`), etc.
- **404** → algún producto no existe (o id mal formado): `"No existe un producto con id \"...\"."`
- **422** → stock insuficiente (nada se modifica):
```json
{ "message": "Ya no hay suficiente Chicle, solo quedan 0.", "error": "Unprocessable Entity", "statusCode": 422 }
```
- **422** → producto descontinuado:
```json
{ "message": "El producto Gomita está descontinuado y ya no se puede vender.", "error": "Unprocessable Entity", "statusCode": 422 }
```
Si varios renglones fallan, el error reportado es el del primero (en el orden del carrito agrupado).

### `GET /api/sales/today`
Totales del **día actual en la zona horaria `America/Mexico_City`** (no UTC): de las 00:00:00 (inclusive) a las 24:00:00 (exclusive) hora de Ciudad de México.

- **200**:
```json
{ "total": 15.9, "totalProfit": 1.6, "salesCount": 1 }
```
Sin ventas hoy: `{ "total": 0, "totalProfit": 0, "salesCount": 0 }`.

### `GET /api/sales`
Historial de ventas, **más recientes primero**. Filtros opcionales por día, siempre en hora de Ciudad de México:

| Query | Formato | Descripción |
|---|---|---|
| `date` | `YYYY-MM-DD` | Solo ese día. Si viene, ignora `from`/`to` |
| `from` | `YYYY-MM-DD` | Desde ese día, inclusive |
| `to` | `YYYY-MM-DD` | Hasta ese día, inclusive |

- **200** → `Sale[]` (`[]` si no hay)
- **400** → formato o fecha inválidos: `["date debe tener formato YYYY-MM-DD"]`, `"date no es una fecha válida (usa YYYY-MM-DD)."` (p. ej. `2026-02-31`)

---

## Notas para el frontend

- **Orden de las rutas:** `GET /sales/today` es una ruta fija, no un id.
- **Stock insuficiente:** el stock mostrado puede estar desactualizado; el 422 es la fuente de verdad. Refrescar `GET /products` tras un 422.
- **Catálogo de venta:** usar `GET /products` (solo activos). Para historial/nombres de productos viejos, `?includeDiscontinued=true` o el `name` copiado en cada venta.
- **Sin DELETE:** no hay endpoints para borrar productos, compras ni ventas (fuera de alcance).
