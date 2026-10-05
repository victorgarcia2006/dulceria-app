import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';
import { opcionesJson } from '../../common';
import { Product } from '../../products/schemas/product.schema';

@Schema({ timestamps: { createdAt: true, updatedAt: false }, toJSON: opcionesJson })
export class Purchase {
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: Product.name, required: true, index: true })
  productId: Types.ObjectId;

  @Prop({ required: true, min: 1 })
  quantity: number;

  @Prop({ required: true, min: 0 })
  unitCost: number;

  createdAt: Date;
}

export type PurchaseDocument = HydratedDocument<Purchase>;
export const PurchaseSchema = SchemaFactory.createForClass(Purchase);
