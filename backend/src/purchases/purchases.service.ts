import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';
import { esObjectIdValido } from '../common';
import { Product, ProductDocument } from '../products/schemas/product.schema';
import { CreatePurchaseDto } from './dto/create-purchase.dto';
import { Purchase, PurchaseDocument } from './schemas/purchase.schema';

@Injectable()
export class PurchasesService {
  constructor(
    @InjectModel(Purchase.name) private readonly purchaseModel: Model<PurchaseDocument>,
    @InjectModel(Product.name) private readonly productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  /**
   * Registra una compra en UNA transacción: verifica el producto, crea la compra,
   * suma el stock y actualiza costPrice a unitCost. Si algo falla, no queda nada a medias.
   */
  async create(dto: CreatePurchaseDto) {
    return this.connection.transaction(async (session) => {
      if (!esObjectIdValido(dto.productId)) {
        throw new NotFoundException(`No existe un producto con id "${dto.productId}".`);
      }

      // El $inc y el $set son atómicos; si el producto no existe, no se crea la compra.
      const producto = await this.productModel
        .findByIdAndUpdate(
          dto.productId,
          { $inc: { stock: dto.quantity }, $set: { costPrice: dto.unitCost } },
          { returnDocument: 'after', session },
        )
        .exec();
      if (!producto) {
        throw new NotFoundException(`No existe un producto con id "${dto.productId}".`);
      }

      const [compra] = await this.purchaseModel.create(
        [{ productId: producto._id, quantity: dto.quantity, unitCost: dto.unitCost }],
        { session },
      );

      return { purchase: compra, product: producto };
    });
  }

  /** Historial, más recientes primero; filtro opcional por producto. */
  findAll(productId?: string) {
    const filtro = productId ? { productId } : {};
    return this.purchaseModel.find(filtro).sort({ createdAt: -1, _id: -1 }).exec();
  }
}
