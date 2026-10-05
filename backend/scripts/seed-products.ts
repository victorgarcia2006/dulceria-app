/**
 * Carga el catálogo inicial usando la API (no toca Mongo directamente).
 *
 *   npm run seed                                   → lee scripts/productos-reales.json
 *   npm run seed -- productos-reales.example.json  → lee otro archivo de scripts/ (o una ruta)
 *   API_URL=http://host:3000/api npm run seed
 *
 * Formato: [{ "name": "...", "costPrice": 2.5, "salePrice": 5, "stock": 20 }]
 * - Cada producto se crea con POST /products.
 * - Si trae stock > 0, se registra con POST /purchases (así queda historial y
 *   el stock sube por la vía normal). Esa compra también fija el costPrice.
 * - Si ya existe un producto con el mismo nombre, se omite (se puede re-correr sin duplicar).
 */
import * as fs from 'fs';
import * as path from 'path';

const API = (process.env.API_URL ?? `http://localhost:${process.env.PORT ?? 3000}/api`).replace(/\/$/, '');

interface ProductoSeed {
  name: string;
  costPrice: number;
  salePrice: number;
  stock?: number;
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
    /* respuesta no JSON */
  }
  return { status: res.status, datos };
}

function mensajeDeError(r: { status: number; datos: any }): string {
  const m = r.datos?.message;
  return `HTTP ${r.status}: ${Array.isArray(m) ? m.join('; ') : (m ?? JSON.stringify(r.datos))}`;
}

function leerArchivo(): ProductoSeed[] {
  const arg = process.argv[2] ?? 'productos-reales.json';
  const ruta = path.isAbsolute(arg) || fs.existsSync(arg) ? arg : path.join(__dirname, arg);
  if (!fs.existsSync(ruta)) {
    console.error(`No existe ${ruta}.\nCopia productos-reales.example.json a productos-reales.json y edítalo.`);
    process.exit(2);
  }
  const datos = JSON.parse(fs.readFileSync(ruta, 'utf8'));
  if (!Array.isArray(datos)) {
    console.error('El archivo debe contener una lista: [{ name, costPrice, salePrice, stock }]');
    process.exit(2);
  }
  console.log(`Leyendo ${ruta} (${datos.length} productos)`);
  return datos;
}

async function main() {
  const productos = leerArchivo();

  const existentes = await llamar('GET', '/products?includeDiscontinued=true').catch(() => null);
  if (!existentes || existentes.status !== 200) {
    console.error(`No se pudo contactar la API en ${API}. ¿Está corriendo el servidor?`);
    process.exit(2);
  }
  const nombresExistentes = new Set((existentes.datos as { name: string }[]).map((p) => p.name.trim().toLowerCase()));

  let creados = 0;
  let omitidos = 0;
  let fallidos = 0;

  for (const p of productos) {
    const etiqueta = p?.name ?? '(sin nombre)';
    if (typeof p?.name === 'string' && nombresExistentes.has(p.name.trim().toLowerCase())) {
      console.log(`  OMITIDO  ${etiqueta} (ya existe)`);
      omitidos++;
      continue;
    }

    const alta = await llamar('POST', '/products', { name: p.name, costPrice: p.costPrice, salePrice: p.salePrice });
    if (alta.status !== 201) {
      console.log(`  ERROR    ${etiqueta} → ${mensajeDeError(alta)}`);
      fallidos++;
      continue;
    }

    const stock = p.stock ?? 0;
    if (stock > 0) {
      const compra = await llamar('POST', '/purchases', {
        productId: alta.datos.id,
        quantity: stock,
        unitCost: p.costPrice,
      });
      if (compra.status !== 201) {
        console.log(`  ERROR    ${etiqueta}: producto creado pero la compra inicial falló → ${mensajeDeError(compra)}`);
        fallidos++;
        continue;
      }
    }
    console.log(`  CREADO   ${etiqueta} (stock inicial: ${stock})`);
    creados++;
    nombresExistentes.add(p.name.trim().toLowerCase());
  }

  console.log(`\nListo: ${creados} creados, ${omitidos} omitidos, ${fallidos} con error.`);
  process.exit(fallidos > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
