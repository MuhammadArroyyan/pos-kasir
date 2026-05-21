class TransactionModel {
  final int? id;
  final String date;
  final int totalAmount;

  TransactionModel({
    this.id,
    required this.date,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_amount': totalAmount,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      date: map['date'],
      totalAmount: map['total_amount'],
    );
  }
}
