import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/error_view.dart';

/// Cash sales history, newest first, with today's total on top.
class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  late Future<List<Sale>> _sales = _fetch();

  Future<List<Sale>> _fetch() => context.read<SaleService>().getSales();

  Future<void> _reload() {
    final future = _fetch();
    setState(() => _sales = future);
    return future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan')),
      body: FutureBuilder<List<Sale>>(
        future: _sales,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(message: '${snapshot.error}', onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = snapshot.data!;
          final now = DateTime.now();
          final today = sales.where(
            (s) =>
                s.saleDate.year == now.year &&
                s.saleDate.month == now.month &&
                s.saleDate.day == now.day,
          );
          final todayTotal = today.fold<double>(
            0,
            (sum, s) => sum + s.totalAmount,
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Penjualan hari ini',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(todayTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${today.length} transaksi',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (sales.isEmpty)
                  const EmptyView(
                    icon: Icons.point_of_sale_outlined,
                    message:
                        'Belum ada penjualan. Bayar tunai dari keranjang untuk mencatatnya.',
                  ),
                for (final sale in sales) _SaleTile(sale),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile(this.sale);

  final Sale sale;

  String get _time =>
      '${sale.saleDate.hour.toString().padLeft(2, '0')}:'
      '${sale.saleDate.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppTheme.success.withValues(alpha: 0.12),
          child: const Icon(Icons.receipt_outlined, color: AppTheme.success),
        ),
        title: Text(
          CurrencyFormatter.format(sale.totalAmount),
          style: textTheme.titleMedium,
        ),
        subtitle: Text(
          '${DateFormatter.display(sale.saleDate)} · $_time · '
          '${sale.items.length} barang',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final item in sale.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} · ${formatQuantity(item.quantity)} '
                      '${item.unitLabel} × ${CurrencyFormatter.format(item.price)}',
                    ),
                  ),
                  Text(CurrencyFormatter.format(item.totalPrice)),
                ],
              ),
            ),
          if (sale.amountReceived != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Diterima ${CurrencyFormatter.format(sale.amountReceived!)}',
                    style: textTheme.bodySmall,
                  ),
                ),
                Text(
                  'Kembalian ${CurrencyFormatter.format(sale.change!)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
