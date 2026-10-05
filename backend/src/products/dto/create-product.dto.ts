import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

const aTexto = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class CreateProductDto {
  @Transform(aTexto)
  @IsString({ message: 'El nombre debe ser texto' })
  @IsNotEmpty({ message: 'El nombre es obligatorio' })
  name: string;

  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'El precio de costo debe ser un número' })
  @Min(0, { message: 'El precio de costo no puede ser negativo' })
  costPrice: number;

  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'El precio de venta debe ser un número' })
  @Min(0, { message: 'El precio de venta no puede ser negativo' })
  salePrice: number;

  @IsOptional()
  @IsInt({ message: 'El stock debe ser un número entero' })
  @Min(0, { message: 'El stock no puede ser negativo' })
  stock?: number;
}
