import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/cart_provider.dart';
import '../database/database_helper.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  _CashierScreenState createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void _scanBarcode(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Scan Barcode')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcodeVal = barcodes.first.rawValue;
                if (barcodeVal != null) {
                  Navigator.pop(context, barcodeVal);
                }
              }
            },
          ),
        ),
      )
    );

    if (barcode != null) {
      _addProductToCart(barcode);
    }
  }

  void _addProductToCart(String barcode) async {
    final dbHelper = DatabaseHelper.instance;
    final product = await dbHelper.getProductByBarcode(barcode);

    if (product != null) {
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).addProduct(product);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk tidak ditemukan!')),
        );
      }
    }
  }

  void _showPaymentDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${formatCurrency.format(cart.totalAmount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Uang Pelanggan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                int amountPaid = int.tryParse(amountController.text) ?? 0;
                if (amountPaid < cart.totalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Uang pelanggan kurang!')),
                  );
                  return;
                }

                // Kalkulasi Kembalian
                final breakdown = cart.calculateChangeBreakdown(amountPaid);
                int change = amountPaid - cart.totalAmount;

                // Proses Checkout
                bool success = await cart.checkout();
                if (mounted) {
                  Navigator.pop(context); // Tutup dialog bayar
                }

                if (success && mounted) {
                  _showChangeDialog(context, change, breakdown);
                }
              },
              child: Text('Bayar'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeDialog(BuildContext context, int change, Map<int, int> breakdown) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transaksi Berhasil!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kembalian: ${formatCurrency.format(change)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              if (breakdown.isNotEmpty) Text('Rincian Pecahan:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...breakdown.entries.map((e) => Text('${e.value} lembar/keping ${formatCurrency.format(e.key)}')),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir POS'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _scanBarcode(context),
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scan Barcode', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('${formatCurrency.format(item.product.price)} x ${item.qty}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.decreaseQty(item.product.barcode),
                            ),
                            Text(formatCurrency.format(item.subtotal), style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(formatCurrency.format(cart.totalAmount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: cart.items.isEmpty ? null : () => _showPaymentDialog(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('BAYAR', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
