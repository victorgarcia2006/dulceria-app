import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { CreateSaleDto } from './dto/create-sale.dto';
import { ListSalesQuery } from './dto/list-sales.query';
import { SalesService } from './sales.service';

@Controller('sales')
export class SalesController {
  constructor(private readonly salesService: SalesService) {}

  @Post()
  create(@Body() dto: CreateSaleDto) {
    return this.salesService.create(dto);
  }

  // Ruta fija: se declara antes de cualquier ruta con parámetros.
  @Get('today')
  today() {
    return this.salesService.today();
  }

  @Get()
  findAll(@Query() query: ListSalesQuery) {
    return this.salesService.findAll(query);
  }
}
