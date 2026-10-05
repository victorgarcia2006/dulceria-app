/**
 * Pruebas end-to-end contra la API REAL (el servidor debe estar corriendo).
 *
 *   npm run e2e                      → usa http://localhost:3000/api
 *   API_URL=http://host:3000/api npm run e2e
 *
 * Al terminar borra de Mongo (conexión directa, vía MONGODB_URI) solo lo que
 * creó la prueba: el producto E2E, sus compras y sus ventas.
 */
import 'dotenv/config';
import * as dns from 'dns';
import * as mongoose from 'mongoose';

const API = (process.env.API_URL ?? `http://localhost:${process.env.PORT ?? 3000}/api`).replace(/\/$/, '');

// Mismo workaround de DNS que usa el servidor (ver src/common/dns.ts).
const dnsServers = (process.env.DNS_SERVERS ?? '').split(',').map((s) => s.trim()).filter(Boolean);
if (dnsServers.length > 0) dns.setServers(dnsServers);

// --- Utilidades mínimas de prueba ---
class FalloDePrueba extends Error {}

function verificar(condicion: boolean, mensaje: string): asserts condicion {
  if (!condicion) throw new FalloDePrueba(mensaje);
}

function igual(real: unknown, esperado: unknown, etiqueta: string) {
  const ok =
    typeof real === 'number' && typeof esperado === 'number'
      ? Math.abs(real - esperado) < 1e-9
      : JSON.stringify(real) === JSON.stringify(esperado);
  verificar(ok, `${etiqueta}: esperado ${JSON.stringify(esperado)}, obtenido ${JSON.stringify(real)}`);
}

async function llamar(metodo: string, ruta: string, cuerpo?: unknown) {
  const res = await fetch(`${API}${ruta}`, {
    method: metodo,
    headers: { 'Content-Type': 'application/json' },
    body: cuerpo === undefined ? undefined : JSON.stringify(cuerpo),
  });
  const texto = await res.text();
  let datos: any = texto;
  try {
    datos = JSON.parse(texto);
  } catch {
    /* respuesta no JSON: se deja como texto */
  }
  return { status: res.status, datos };
}

// --- Estado de la prueba ---
const nombre = `E2E Gomitas ${Date.now()}`;
let productId = '';
const creado = { purchaseIds: [] as string[], saleIds: [] as string[] };
let hoyAntes = { total: 0, totalProfit: 0, salesCount: 0 };
const resultados: { paso: string; ok: boolean; detalle?: string }[] = [];

async function paso(titulo: string, fn: () => Promise<void>): Promise<boolean> {
  try {
    await fn();
    resultados.push({ paso: titulo, ok: true });
    console.log(`  PASÓ   ${titulo}`);
    return true;
  } catch (e) {
    const detalle = e instanceof Error ? e.message : String(e);
    resultados.push({ paso: titulo, ok: false, detalle });
    console.log(`  FALLÓ  ${titulo}\n         ${detalle}`);
    return false;
  }
}

async function limpiar() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.log('  (sin MONGODB_URI: no se pudo limpiar la base)');
    return;
  }
  const conexion = await mongoose.createConnection(uri).asPromise();
  try {
    const db = conexion.db!;
    const oid = (id: string) => new mongoose.Types.ObjectId(id);
    let ventas = 0;
    let compras = 0;
    let productos = 0;
    if (productId) {
      ventas = (await db.collection('sales').deleteMany({ 'items.productId': oid(productId) })).deletedCount;
      compras = (await db.collection('purchases').deleteMany({ productId: oid(productId) })).deletedCount;
      productos = (await db.collection('products').deleteMany({ _id: oid(productId) })).deletedCount;
    }
    console.log(`  Limpieza: ${productos} producto, ${compras} compras, ${ventas} ventas borrados.`);
  } finally {
    await conexion.close();
  }
}

async function main() {
  console.log(`\nE2E contra ${API}\n`);

  const vivo = await llamar('GET', '/products').catch(() => null);
  if (!vivo || vivo.status !== 200) {
    console.error('No se pudo contactar la API. ¿Está corriendo el servidor? (npm run start)');
    process.exit(2);
  }
  hoyAntes = (await llamar('GET', '/sales/today')).datos;

  let sigue = await paso('1. Crear producto', async () => {
    const r = await llamar('POST', '/products', { name: nombre, costPrice: 1, salePrice: 4 });
    igual(r.status, 201, 'status');
    verificar(typeof r.datos.id === 'string' && r.datos._id === undefined, 'el producto debe traer `id` (string) y no `_id`');
    igual(r.datos.stock, 0, 'stock inicial');
    igual(r.datos.active, true, 'active');
    productId = r.datos.id;
  });

  if (sigue) {
    sigue = await paso('2. Comprar 20 uds a costo 2.5 → stock 20, costPrice 2.5', async () => {
      const r = await llamar('POST', '/purchases', { productId, quantity: 20, unitCost: 2.5 });
      igual(r.status, 201, 'status');
      creado.purchaseIds.push(r.datos.purchase.id);
      igual(r.datos.product.stock, 20, 'stock en la respuesta');
      igual(r.datos.product.costPrice, 2.5, 'costPrice en la respuesta');
      const lista = (await llamar('GET', '/products')).datos as any[];
      const p = lista.find((x) => x.id === productId);
      verificar(!!p, 'el producto debe aparecer en GET /products');
      igual(p.stock, 20, 'stock persistido');
      igual(p.costPrice, 2.5, 'costPrice persistido');
    });
  }

  if (sigue) {
    sigue = await paso('3. Vender 5 → profit, total y totalProfit correctos, stock 15', async () => {
      const r = await llamar('POST', '/sales', { items: [{ productId, quantity: 5 }] });
      igual(r.status, 201, 'status');
      creado.saleIds.push(r.datos.id);
      const item = r.datos.items[0];
      igual(item.name, nombre, 'nombre copiado');
      igual(item.unitCostAtSale, 2.5, 'unitCostAtSale');
      igual(item.unitSalePrice, 4, 'unitSalePrice');
      igual(item.profit, 7.5, 'profit = (4 − 2.5) × 5');
      igual(r.datos.total, 20, 'total = 4 × 5');
      igual(r.datos.totalProfit, 7.5, 'totalProfit');
      const p = ((await llamar('GET', '/products')).datos as any[]).find((x) => x.id === productId);
      igual(p.stock, 15, 'stock tras vender');
    });
  }

  if (sigue) {
    sigue = await paso('4. GET /sales/today refleja la venta', async () => {
      const r = await llamar('GET', '/sales/today');
      igual(r.status, 200, 'status');
      igual(r.datos.salesCount - hoyAntes.salesCount, 1, 'ventas de hoy (diferencia)');
      igual(Math.round((r.datos.total - hoyAntes.total) * 100) / 100, 20, 'total de hoy (diferencia)');
      igual(Math.round((r.datos.totalProfit - hoyAntes.totalProfit) * 100) / 100, 7.5, 'ganancia de hoy (diferencia)');
    });
  }

  if (sigue) {
    sigue = await paso('5. Vender 16 sobre 15 → 422 y stock sigue en 15', async () => {
      const r = await llamar('POST', '/sales', { items: [{ productId, quantity: 16 }] });
      igual(r.status, 422, 'status');
      verificar(
        typeof r.datos.message === 'string' && r.datos.message.includes(nombre) && r.datos.message.includes('15'),
        `el mensaje debe incluir el nombre y las unidades restantes; fue: ${JSON.stringify(r.datos.message)}`,
      );
      const p = ((await llamar('GET', '/products')).datos as any[]).find((x) => x.id === productId);
      igual(p.stock, 15, 'stock tras el rechazo');
    });
  }

  if (sigue) {
    await paso('6. Descontinuar → oculto en GET /products, visible con includeDiscontinued, GET /sales conserva el nombre', async () => {
      const d = await llamar('PATCH', `/products/${productId}/discontinue`);
      igual(d.status, 200, 'status de discontinue');
      igual(d.datos.active, false, 'active');

      const activos = (await llamar('GET', '/products')).datos as any[];
      verificar(!activos.some((x) => x.id === productId), 'no debe salir en GET /products');

      const todos = (await llamar('GET', '/products?includeDiscontinued=true')).datos as any[];
      verificar(todos.some((x) => x.id === productId), 'debe salir con includeDiscontinued=true');

      const ventas = (await llamar('GET', '/sales')).datos as any[];
      const venta = ventas.find((v) => v.id === creado.saleIds[0]);
      verificar(!!venta, 'la venta debe seguir en GET /sales');
      igual(venta.items[0].name, nombre, 'nombre conservado en la venta');
    });
  }

  console.log('');
  await limpiar().catch((e) => console.log(`  Error al limpiar: ${e instanceof Error ? e.message : e}`));

  const fallos = resultados.filter((r) => !r.ok).length;
  const omitidos = 6 - resultados.length;
  console.log(
    `\nResultado: ${resultados.length - fallos} pasaron, ${fallos} fallaron` + (omitidos ? `, ${omitidos} omitidos` : '') + '\n',
  );
  process.exit(fallos > 0 || omitidos > 0 ? 1 : 0);
}

main().catch(async (e) => {
  console.error(e);
  await limpiar().catch(() => undefined);
  process.exit(1);
});
