import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../database/database_helper.dart';

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});
  
  int get subtotal => product.price * qty;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  void addProduct(Product product) {
    // Cek apakah produk sudah ada di keranjang berdasarkan barcode
    final index = _items.indexWhere((item) => item.product.barcode == product.barcode);
    if (index >= 0) {
      // Jika produk ada, tambah qty
      _items[index].qty++;
    } else {
      // Jika baru, tambahkan ke list
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeProduct(String barcode) {
    _items.removeWhere((item) => item.product.barcode == barcode);
    notifyListeners();
  }

  void decreaseQty(String barcode) {
    final index = _items.indexWhere((item) => item.product.barcode == barcode);
    if (index >= 0) {
      if (_items[index].qty > 1) {
        _items[index].qty--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Fungsi Checkout
  Future<bool> checkout() async {
    if (_items.isEmpty) return false;

    final db = DatabaseHelper.instance;
    final now = DateTime.now().toIso8601String();

    // 1. Simpan Transaksi
    final transaction = TransactionModel(date: now, totalAmount: totalAmount);
    final transactionId = await db.insertTransaction(transaction);

    // 2. Simpan Item Transaksi & Kurangi Stok
    for (var item in _items) {
      final tItem = TransactionItem(
        transactionId: transactionId,
        productId: item.product.id!,
        qty: item.qty,
        subtotal: item.subtotal,
      );
      await db.insertTransactionItem(tItem);

      // Kurangi stok produk
      final newStock = item.product.stock - item.qty;
      await db.updateProductStock(item.product.id!, newStock >= 0 ? newStock : 0);
    }

    clearCart();
    return true;
  }

  // Kalkulator Pecahan Kembalian
  Map<int, int> calculateChangeBreakdown(int amountPaid) {
    int change = amountPaid - totalAmount;
    if (change <= 0) return {};

    final List<int> denominations = [100000, 50000, 20000, 10000, 5000, 2000, 1000, 500];
    Map<int, int> breakdown = {};

    for (int note in denominations) {
      if (change >= note) {
        int count = change ~/ note;
        breakdown[note] = count;
        change = change % note;
      }
    }

    return breakdown;
  }
}
