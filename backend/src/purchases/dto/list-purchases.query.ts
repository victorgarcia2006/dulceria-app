import { IsMongoId, IsOptional } from 'class-validator';

export class ListPurchasesQuery {
  @IsOptional()
  @IsMongoId({ message: 'productId no es un id válido' })
  productId?: string;
}
