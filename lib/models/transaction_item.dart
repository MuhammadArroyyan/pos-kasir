class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int qty;
  final int subtotal;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.qty,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'qty': qty,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      qty: map['qty'],
      subtotal: map['subtotal'],
    );
  }
}
