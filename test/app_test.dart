import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warunku/main.dart';
import 'package:warunku/services/api_client.dart';

/// Request bodies the fake backend received for POST /api/sales.
final _postedSales = <Map<String, dynamic>>[];

/// Fake backend with one product and one customer; accepts cash sales.
final _backend = MockClient((request) async {
  if (request.method == 'POST' && request.url.path == '/api/sales') {
    final sale = jsonDecode(request.body) as Map<String, dynamic>;
    _postedSales.add(sale);
    return http.Response(
      jsonEncode({
        '_id': 's1',
        'items': [
          {
            'productName': 'Rice',
            'unitLabel': 'kg',
            'quantity': 1,
            'price': 12000,
            'totalPrice': 12000,
          },
        ],
        'totalAmount': 12000,
        'amountReceived': sale['amountReceived'],
        'saleDate': '2026-11-26T10:00:00.000Z',
      }),
      201,
    );
  }
  final body = switch (request.url.path) {
    '/api/products' => [
      {
        '_id': 'p1',
        'name': 'Rice',
        'category': 'Food',
        'units': [
          {'label': 'kg', 'sellingPrice': 12000, 'stock': 10},
        ],
      },
    ],
    '/api/customers' => {
      'customers': [
        {'_id': 'c1', 'name': 'Budi'},
      ],
      'currentPage': 1,
      'totalPages': 1,
      'totalCustomers': 1,
    },
    _ => null,
  };
  return http.Response(jsonEncode(body), body == null ? 404 : 200);
});

void main() {
  testWidgets('lists products and opens the debt form from a customer', (
    tester,
  ) async {
    await tester.pumpWidget(
      WarunkuApp(
        apiClient: ApiClient(client: _backend, baseUrl: 'http://test/api'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsOneWidget);

    await tester.tap(find.text('Pelanggan'));
    await tester.pumpAndSettle();
    // Tapping the row opens the ledger; the row's quick action opens the form.
    await tester.tap(find.byTooltip('Catat Utang'));
    await tester.pumpAndSettle();

    // Used to throw ProviderNotFoundException for DebtBloc.
    expect(find.text('Catat Utang Baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart: add a product and pay cash', (tester) async {
    _postedSales.clear();
    await tester.pumpWidget(
      WarunkuApp(
        apiClient: ApiClient(client: _backend, baseUrl: 'http://test/api'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lihat keranjang'), findsNothing);

    await tester.tap(find.byTooltip('Tambah ke keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Stok 10 kg'), findsOneWidget);
    await tester.tap(find.text('Lihat keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang'), findsOneWidget);

    await tester.tap(find.text('Bayar Tunai'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.pumpAndSettle();
    expect(find.text('Kembalian: Rp 8.000'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(_postedSales.single, {
      'items': [
        {'product': 'p1', 'unitLabel': 'kg', 'quantity': 1.0},
      ],
      'amountReceived': 20000.0,
    });
    // Back on the product list with an empty cart.
    expect(find.text('Lihat keranjang'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart: record as debt prefills the debt form', (tester) async {
    await tester.pumpWidget(
      WarunkuApp(
        apiClient: ApiClient(client: _backend, baseUrl: 'http://test/api'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tambah ke keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat keranjang'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadikan Utang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();

    expect(find.text('Catat Utang Baru'), findsOneWidget);
    expect(find.text('Rice (kg)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
