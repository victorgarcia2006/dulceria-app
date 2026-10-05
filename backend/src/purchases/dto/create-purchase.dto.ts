import { IsInt, IsNotEmpty, IsNumber, IsString, Min } from 'class-validator';

export class CreatePurchaseDto {
  @IsString({ message: 'El id del producto debe ser texto' })
  @IsNotEmpty({ message: 'El id del producto es obligatorio' })
  productId: string;

  @IsInt({ message: 'La cantidad debe ser un número entero' })
  @Min(1, { message: 'La cantidad debe ser mayor a 0' })
  quantity: number;

  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'El costo unitario debe ser un número' })
  @Min(0, { message: 'El costo unitario no puede ser negativo' })
  unitCost: number;
}
