import '../blocs/cart/cart_cubit.dart';
import '../models/sale.dart';
import 'api_client.dart';

class SaleService {
  SaleService(this._api);

  final ApiClient _api;

  /// Records a cash sale. Prices are taken from the server's product data.
  Future<Sale> createSale(
    List<CartLine> lines, {
    double? amountReceived,
  }) async => Sale.fromJson(
    await _api.post('/sales', {
      'items': [
        for (final line in lines)
          {
            'product': line.product.id,
            'unitLabel': line.unit.label,
            'quantity': line.quantity,
          },
      ],
      if (amountReceived != null) 'amountReceived': amountReceived,
    }),
  );

  // shortcut: newest 50 only, no paging; add page/infinite scroll once a
  // shop has more sales than that worth browsing.
  Future<List<Sale>> getSales() async {
    final data = await _api.get('/sales', query: {'limit': '50'});
    return ((data as Map<String, dynamic>)['sales'] as List<dynamic>)
        .map((s) => Sale.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}
