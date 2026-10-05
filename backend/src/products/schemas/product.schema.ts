import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { opcionesJson } from '../../common';

@Schema({ toJSON: opcionesJson })
export class Product {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, min: 0 })
  costPrice: number;

  @Prop({ required: true, min: 0 })
  salePrice: number;

  @Prop({ required: true, min: 0, default: 0 })
  stock: number;

  @Prop({ required: true, default: true })
  active: boolean;
}

export type ProductDocument = HydratedDocument<Product>;
export const ProductSchema = SchemaFactory.createForClass(Product);
