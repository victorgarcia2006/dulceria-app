import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';
import { opcionesJson } from '../../common';
import { Product } from '../../products/schemas/product.schema';

/** Renglón de la venta: copia (congela) nombre, costo y precio al momento de vender. */
@Schema({ _id: false })
export class SaleItem {
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: Product.name, required: true })
  productId: Types.ObjectId;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true, min: 1 })
  quantity: number;

  @Prop({ required: true, min: 0 })
  unitCostAtSale: number;

  @Prop({ required: true, min: 0 })
  unitSalePrice: number;

  @Prop({ required: true })
  profit: number;
}
export const SaleItemSchema = SchemaFactory.createForClass(SaleItem);

@Schema({ timestamps: { createdAt: true, updatedAt: false }, toJSON: opcionesJson })
export class Sale {
  @Prop({ type: [SaleItemSchema], required: true })
  items: SaleItem[];

  @Prop({ required: true, min: 0 })
  total: number;

  @Prop({ required: true })
  totalProfit: number;

  createdAt: Date;
}

export type SaleDocument = HydratedDocument<Sale>;
export const SaleSchema = SchemaFactory.createForClass(Sale);
// El historial y "ventas de hoy" filtran y ordenan por fecha.
SaleSchema.index({ createdAt: -1 });
