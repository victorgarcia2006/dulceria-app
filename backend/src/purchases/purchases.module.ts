import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductsModule } from '../products/products.module';
import { PurchasesController } from './purchases.controller';
import { PurchasesService } from './purchases.service';
import { Purchase, PurchaseSchema } from './schemas/purchase.schema';

@Module({
  imports: [ProductsModule, MongooseModule.forFeature([{ name: Purchase.name, schema: PurchaseSchema }])],
  controllers: [PurchasesController],
  providers: [PurchasesService],
})
export class PurchasesModule {}
