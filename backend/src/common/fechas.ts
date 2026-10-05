import { ZONA_HORARIA } from './utils';

/**
 * Rangos de fechas en la zona horaria del negocio (America/Mexico_City).
 *
 * No se usa el "día UTC": se calcula el instante UTC exacto en el que empieza
 * el día local, usando Intl para obtener el desfase real de la zona en esa fecha
 * (así también funciona si la zona tuviera horario de verano).
 */

const formateador = new Intl.DateTimeFormat('en-US', {
  timeZone: ZONA_HORARIA,
  hourCycle: 'h23',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
});

/** Fecha local (año, mes, día) de un instante en la zona del negocio. */
function partesLocales(instante: Date) {
  const partes: Record<string, number> = {};
  for (const p of formateador.formatToParts(instante)) {
    if (p.type !== 'literal') partes[p.type] = Number(p.value);
  }
  return partes;
}

/** Desfase (ms) de la zona respecto a UTC en un instante dado: hora local − hora UTC. */
function desfaseMs(instante: Date): number {
  const p = partesLocales(instante);
  const comoUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return comoUtc - Math.floor(instante.getTime() / 1000) * 1000;
}

/** Instante UTC en el que es medianoche local del día (y, m, d) en la zona del negocio. */
function inicioDiaLocal(y: number, m: number, d: number): Date {
  const adivinado = Date.UTC(y, m - 1, d, 0, 0, 0);
  let utc = adivinado - desfaseMs(new Date(adivinado));
  // Segunda pasada: corrige si el desfase cambió entre la estimación y el instante real.
  utc = adivinado - desfaseMs(new Date(utc));
  return new Date(utc);
}

export interface RangoFechas {
  /** Inclusivo */
  inicio: Date;
  /** Exclusivo */
  fin: Date;
}

/** Rango [inicio, fin) del día local que contiene a `instante`. */
export function rangoDelDia(instante: Date = new Date()): RangoFechas {
  const { year, month, day } = partesLocales(instante);
  return rangoDeFecha(year, month, day);
}

/** Rango [inicio, fin) del día local indicado. */
export function rangoDeFecha(y: number, m: number, d: number): RangoFechas {
  // Date.UTC normaliza el desborde de día/mes (p. ej. día 32 → día 1 del mes siguiente).
  const siguiente = new Date(Date.UTC(y, m - 1, d + 1));
  return {
    inicio: inicioDiaLocal(y, m, d),
    fin: inicioDiaLocal(siguiente.getUTCFullYear(), siguiente.getUTCMonth() + 1, siguiente.getUTCDate()),
  };
}

const FECHA_REGEX = /^(\d{4})-(\d{2})-(\d{2})$/;

/** Interpreta "YYYY-MM-DD" como día local; devuelve null si el formato o la fecha no son válidos. */
export function parsearFecha(texto: string): { y: number; m: number; d: number } | null {
  const match = FECHA_REGEX.exec(texto);
  if (!match) return null;
  const [y, m, d] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const control = new Date(Date.UTC(y, m - 1, d));
  if (control.getUTCFullYear() !== y || control.getUTCMonth() !== m - 1 || control.getUTCDate() !== d) {
    return null;
  }
  return { y, m, d };
}
