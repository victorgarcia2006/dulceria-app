import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { CreatePurchaseDto } from './dto/create-purchase.dto';
import { ListPurchasesQuery } from './dto/list-purchases.query';
import { PurchasesService } from './purchases.service';

@Controller('purchases')
export class PurchasesController {
  constructor(private readonly purchasesService: PurchasesService) {}

  @Post()
  create(@Body() dto: CreatePurchaseDto) {
    return this.purchasesService.create(dto);
  }

  @Get()
  findAll(@Query() query: ListPurchasesQuery) {
    return this.purchasesService.findAll(query.productId);
  }
}
