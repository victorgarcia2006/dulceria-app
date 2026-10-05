import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsInt, IsNotEmpty, IsString, Min, ValidateNested } from 'class-validator';

export class SaleItemDto {
  @IsString({ message: 'El id del producto debe ser texto' })
  @IsNotEmpty({ message: 'El id del producto es obligatorio' })
  productId: string;

  @IsInt({ message: 'La cantidad debe ser un número entero' })
  @Min(1, { message: 'La cantidad debe ser mayor a 0' })
  quantity: number;
}

export class CreateSaleDto {
  @IsArray({ message: 'items debe ser una lista' })
  @ArrayMinSize(1, { message: 'La venta debe tener al menos un producto' })
  @ValidateNested({ each: true })
  @Type(() => SaleItemDto)
  items: SaleItemDto[];
}
