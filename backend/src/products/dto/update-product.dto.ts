import { Transform } from 'class-transformer';
import { Equals, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

const aTexto = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class UpdateProductDto {
  @IsOptional()
  @Transform(aTexto)
  @IsString({ message: 'El nombre debe ser texto' })
  @IsNotEmpty({ message: 'El nombre no puede estar vacío' })
  name?: string;

  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'El precio de costo debe ser un número' })
  @Min(0, { message: 'El precio de costo no puede ser negativo' })
  costPrice?: number;

  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'El precio de venta debe ser un número' })
  @Min(0, { message: 'El precio de venta no puede ser negativo' })
  salePrice?: number;

  /**
   * El stock nunca se edita aquí (solo cambia con compras y ventas).
   * Se declara solo para rechazarlo con 400: sin este decorador, `whitelist`
   * lo eliminaría en silencio en lugar de avisar.
   */
  @Equals(undefined, { message: 'El stock no se puede editar aquí; usa compras (suma) o ventas (resta)' })
  stock?: never;
}
