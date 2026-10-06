/// Producto del catálogo (ver `docs/api-contract.md`).
/// En la API el campo de existencias se llama `stock`; aquí lo llamamos
/// [existencias] para mantener el vocabulario de la app.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.salePrice,
    required this.existencias,
    required this.active,
  });

  final String id;
  final String name;
  final double costPrice;
  final double salePrice;
  final int existencias;

  /// `false` = descontinuado.
  final bool active;

  bool get agotado => existencias <= 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        costPrice: (json['costPrice'] as num).toDouble(),
        salePrice: (json['salePrice'] as num).toDouble(),
        existencias: (json['stock'] as num).toInt(),
        active: json['active'] as bool,
      );
}

/// Totales del día (`GET /sales/today`).
class TodaySummary {
  const TodaySummary({
    required this.total,
    required this.totalProfit,
    required this.salesCount,
  });

  final double total;
  final double totalProfit;
  final int salesCount;

  factory TodaySummary.fromJson(Map<String, dynamic> json) => TodaySummary(
        total: (json['total'] as num).toDouble(),
        totalProfit: (json['totalProfit'] as num).toDouble(),
        salesCount: (json['salesCount'] as num).toInt(),
      );
}

/// Renglón que se manda al registrar una venta.
class ItemVenta {
  const ItemVenta({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'quantity': quantity};
}

/// Venta registrada (`POST /sales`); solo guardamos lo que la app muestra.
class Sale {
  const Sale({required this.id, required this.total, required this.totalProfit});

  final String id;
  final double total;
  final double totalProfit;

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
        totalProfit: (json['totalProfit'] as num).toDouble(),
      );
}
