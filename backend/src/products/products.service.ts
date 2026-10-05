import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { esObjectIdValido } from '../common';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { Product, ProductDocument } from './schemas/product.schema';

@Injectable()
export class ProductsService {
  constructor(@InjectModel(Product.name) private readonly productModel: Model<ProductDocument>) {}

  /** Solo activos, salvo que se pidan también los descontinuados. */
  findAll(includeDiscontinued = false) {
    const filtro = includeDiscontinued ? {} : { active: true };
    return this.productModel.find(filtro).sort({ name: 1 }).exec();
  }

  create(dto: CreateProductDto) {
    return this.productModel.create(dto);
  }

  async update(id: string, dto: UpdateProductDto) {
    this.validarId(id);
    const cambios: Partial<Pick<Product, 'name' | 'costPrice' | 'salePrice'>> = {};
    if (dto.name !== undefined) cambios.name = dto.name;
    if (dto.costPrice !== undefined) cambios.costPrice = dto.costPrice;
    if (dto.salePrice !== undefined) cambios.salePrice = dto.salePrice;

    const producto = await this.productModel
      .findByIdAndUpdate(id, { $set: cambios }, { returnDocument: 'after', runValidators: true })
      .exec();
    if (!producto) throw this.noEncontrado(id);
    return producto;
  }

  /** No borra: solo marca active=false para conservar el historial. */
  async discontinue(id: string) {
    this.validarId(id);
    const producto = await this.productModel
      .findByIdAndUpdate(id, { $set: { active: false } }, { returnDocument: 'after' })
      .exec();
    if (!producto) throw this.noEncontrado(id);
    return producto;
  }

  private validarId(id: string) {
    if (!esObjectIdValido(id)) throw this.noEncontrado(id);
  }

  private noEncontrado(id: string) {
    return new NotFoundException(`No existe un producto con id "${id}".`);
  }
}
