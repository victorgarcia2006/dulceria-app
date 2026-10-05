import { BadRequestException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';
import { esObjectIdValido, parsearFecha, rangoDeFecha, rangoDelDia, redondear2 } from '../common';
import { Product, ProductDocument } from '../products/schemas/product.schema';
import { CreateSaleDto } from './dto/create-sale.dto';
import { ListSalesQuery } from './dto/list-sales.query';
import { Sale, SaleDocument, SaleItem } from './schemas/sale.schema';

@Injectable()
export class SalesService {
  constructor(
    @InjectModel(Sale.name) private readonly saleModel: Model<SaleDocument>,
    @InjectModel(Product.name) private readonly productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  /**
   * Registra una venta (todo o nada) en una transacción:
   * 1) carga y valida TODOS los productos antes de modificar nada;
   * 2) congela costo/precio/nombre en cada renglón y calcula la ganancia;
   * 3) descuenta stock y guarda la venta.
   */
  async create(dto: CreateSaleDto) {
    const pedidos = this.agruparPorProducto(dto);

    return this.connection.transaction(async (session) => {
      // --- 1) Validación completa, sin escribir nada ---
      const productos = new Map<string, ProductDocument>();
      for (const { productId, quantity } of pedidos) {
        if (!esObjectIdValido(productId)) throw this.noEncontrado(productId);
        const producto = await this.productModel.findById(productId).session(session).exec();
        if (!producto) throw this.noEncontrado(productId);
        if (!producto.active) {
          throw new UnprocessableEntityException(
            `El producto ${producto.name} está descontinuado y ya no se puede vender.`,
          );
        }
        if (producto.stock < quantity) {
          throw new UnprocessableEntityException(
            `Ya no hay suficiente ${producto.name}, solo quedan ${producto.stock}.`,
          );
        }
        productos.set(productId, producto);
      }

      // --- 2) y 3) Descuento de stock y armado de la venta ---
      const items: SaleItem[] = [];
      for (const { productId, quantity } of pedidos) {
        const producto = productos.get(productId)!;
        // Condicional: aunque otra operación se cuele, el stock nunca queda en negativo.
        const actualizado = await this.productModel
          .findOneAndUpdate(
            { _id: producto._id, active: true, stock: { $gte: quantity } },
            { $inc: { stock: -quantity } },
            { returnDocument: 'after', session },
          )
          .exec();
        if (!actualizado) {
          throw new UnprocessableEntityException(
            `Ya no hay suficiente ${producto.name}, solo quedan ${producto.stock}.`,
          );
        }
        items.push({
          productId: producto._id,
          name: producto.name,
          quantity,
          unitCostAtSale: producto.costPrice,
          unitSalePrice: producto.salePrice,
          profit: redondear2((producto.salePrice - producto.costPrice) * quantity),
        });
      }

      const total = redondear2(items.reduce((suma, i) => suma + i.unitSalePrice * i.quantity, 0));
      const totalProfit = redondear2(items.reduce((suma, i) => suma + i.profit, 0));

      const [venta] = await this.saleModel.create([{ items, total, totalProfit }], { session });
      return venta;
    });
  }

  /** Totales del día actual en America/Mexico_City (ceros si no hay ventas). */
  async today() {
    const { inicio, fin } = rangoDelDia();
    const [resultado] = await this.saleModel
      .aggregate<{ total: number; totalProfit: number; salesCount: number }>([
        { $match: { createdAt: { $gte: inicio, $lt: fin } } },
        {
          $group: {
            _id: null,
            total: { $sum: '$total' },
            totalProfit: { $sum: '$totalProfit' },
            salesCount: { $sum: 1 },
          },
        },
      ])
      .exec();

    return {
      total: redondear2(resultado?.total ?? 0),
      totalProfit: redondear2(resultado?.totalProfit ?? 0),
      salesCount: resultado?.salesCount ?? 0,
    };
  }

  /** Historial, más recientes primero. Filtros opcionales por día (hora de Ciudad de México). */
  findAll(query: ListSalesQuery) {
    const filtroFecha: { $gte?: Date; $lt?: Date } = {};

    if (query.date) {
      const { inicio, fin } = rangoDeFecha(...this.fechaOFallar('date', query.date));
      filtroFecha.$gte = inicio;
      filtroFecha.$lt = fin;
    } else {
      if (query.from) filtroFecha.$gte = rangoDeFecha(...this.fechaOFallar('from', query.from)).inicio;
      if (query.to) filtroFecha.$lt = rangoDeFecha(...this.fechaOFallar('to', query.to)).fin;
    }

    const filtro = Object.keys(filtroFecha).length > 0 ? { createdAt: filtroFecha } : {};
    return this.saleModel.find(filtro).sort({ createdAt: -1, _id: -1 }).exec();
  }

  /** Une los renglones repetidos del mismo producto sumando cantidades (conserva el orden). */
  private agruparPorProducto(dto: CreateSaleDto) {
    const mapa = new Map<string, number>();
    for (const item of dto.items) {
      mapa.set(item.productId, (mapa.get(item.productId) ?? 0) + item.quantity);
    }
    return [...mapa].map(([productId, quantity]) => ({ productId, quantity }));
  }

  private fechaOFallar(campo: string, valor: string): [number, number, number] {
    const f = parsearFecha(valor);
    if (!f) throw new BadRequestException(`${campo} no es una fecha válida (usa YYYY-MM-DD).`);
    return [f.y, f.m, f.d];
  }

  private noEncontrado(id: string) {
    return new NotFoundException(`No existe un producto con id "${id}".`);
  }
}
