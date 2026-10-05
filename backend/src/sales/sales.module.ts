import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductsModule } from '../products/products.module';
import { Sale, SaleSchema } from './schemas/sale.schema';
import { SalesController } from './sales.controller';
import { SalesService } from './sales.service';

@Module({
  imports: [ProductsModule, MongooseModule.forFeature([{ name: Sale.name, schema: SaleSchema }])],
  controllers: [SalesController],
  providers: [SalesService],
})
export class SalesModule {}
