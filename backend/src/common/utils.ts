import { SchemaOptions } from '@nestjs/mongoose';

/** Zona horaria del negocio: define qué significa "hoy". */
export const ZONA_HORARIA = 'America/Mexico_City';

const OBJECT_ID_REGEX = /^[a-f\d]{24}$/i;

/** Valida un ObjectId de 24 caracteres hex (isValid de Mongoose acepta también strings de 12 chars). */
export function esObjectIdValido(id: unknown): id is string {
  return typeof id === 'string' && OBJECT_ID_REGEX.test(id);
}

/** Redondea a 2 decimales para evitar errores de punto flotante en dinero. */
export function redondear2(valor: number): number {
  return Math.round((valor + Number.EPSILON) * 100) / 100;
}

/** toJSON común: expone `id` (string) y oculta `_id` y `__v`. */
export const opcionesJson: SchemaOptions['toJSON'] = {
  versionKey: false,
  transform: (_doc, ret: Record<string, any>) => {
    ret.id = String(ret._id);
    delete ret._id;
    return ret;
  },
};
