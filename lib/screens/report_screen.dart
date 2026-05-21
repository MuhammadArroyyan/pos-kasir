import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<TransactionModel> _transactions = [];
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    final transactions = await dbHelper.getTodayTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _exportToWhatsApp() async {
    int totalSales = _transactions.fold(0, (sum, item) => sum + item.totalAmount);
    String date = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    String report = "Laporan Penjualan - $date\n\n";
    report += "Total Transaksi: ${_transactions.length}\n";
    report += "Total Pendapatan: ${formatCurrency.format(totalSales)}\n\n";
    report += "Rincian Transaksi:\n";
    for (var i = 0; i < _transactions.length; i++) {
      report += "${i + 1}. ${formatCurrency.format(_transactions[i].totalAmount)}\n";
    }

    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(report)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Hari Ini'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _exportToWhatsApp,
            tooltip: 'Kirim Laporan via WA',
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          final dateStr = DateFormat('HH:mm').format(DateTime.parse(tx.date));
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Transaksi #$dateStr'),
            trailing: Text(formatCurrency.format(tx.totalAmount)),
          );
        },
      ),
    );
  }
}
