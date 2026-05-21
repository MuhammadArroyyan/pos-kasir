class Product {
  final int? id;
  final String barcode;
  final String name;
  final int price;
  final int stock;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
    );
  }
}
