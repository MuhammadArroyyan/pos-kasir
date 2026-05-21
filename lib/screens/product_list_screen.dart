import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Product> _products = [];
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final products = await dbHelper.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  void _showAddProductDialog(BuildContext context, {String? scannedBarcode}) {
    final barcodeController = TextEditingController(text: scannedBarcode);
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode', 
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        Navigator.pop(context);
                        _scanBarcodeForProduct();
                      },
                    )
                  ),
                ),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: priceController, decoration: InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
                TextField(controller: stockController, decoration: InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final product = Product(
                    barcode: barcodeController.text,
                    name: nameController.text,
                    price: int.tryParse(priceController.text) ?? 0,
                    stock: int.tryParse(stockController.text) ?? 0,
                  );
                  await dbHelper.insertProduct(product);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadProducts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 5)),
                    );
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _scanBarcodeForProduct() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Scan Barcode Produk')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  Navigator.pop(context, barcode);
                }
              }
            },
          ),
        ),
      )
    );

    if (result != null) {
      _showAddProductDialog(context, scannedBarcode: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Produk'),
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('Barcode: ${product.barcode} | Stok: ${product.stock}'),
            trailing: Text(formatCurrency.format(product.price)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
