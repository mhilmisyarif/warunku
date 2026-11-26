import 'package:flutter_test/flutter_test.dart';
import 'package:warunku/models/debt_record.dart';
import 'package:warunku/utils/formatter.dart';

void main() {
  final debtJson = {
    '_id': 'd1',
    'customer': {'_id': 'c1', 'name': 'Budi'},
    'items': [
      {
        'product': {'_id': 'p1'},
        'productName': 'Rice',
        'unitLabel': 'kg',
        'quantity': 2,
        'priceAtTimeOfDebt': 12000,
        'totalPrice': 24000,
      },
    ],
    'totalAmount': 24000,
    'amountPaid': 4000,
    'status': 'PARTIALLY_PAID',
    'paymentHistory': [
      {'amount': 4000, 'paymentDate': '2026-11-01T00:00:00.000Z'},
    ],
    'debtDate': '2026-11-01T00:00:00.000Z',
  };

  test('DebtRecord.fromJson handles a populated customer', () {
    final debt = DebtRecord.fromJson(debtJson);
    expect(debt.customerId, 'c1');
    expect(debt.customerName, 'Budi');
    expect(debt.items.single.productId, 'p1');
    expect(debt.status, DebtStatus.partiallyPaid);
    expect(debt.remainingBalance, 20000);
    expect(debt.paymentHistory.single.amount, 4000);
  });

  test('DebtRecord.fromJson handles a customer id string', () {
    final debt = DebtRecord.fromJson({...debtJson, 'customer': 'c9'});
    expect(debt.customerId, 'c9');
    expect(debt.customer, isNull);
  });

  test('DebtRecord.toJson sends the initial payment the API reads', () {
    final debt = DebtRecord(
      customerId: 'c1',
      items: const [],
      totalAmount: 10000,
      amountPaid: 2500,
      debtDate: DateTime(2026, 11, 1),
    );
    final json = debt.toJson();
    expect(json['customer'], 'c1');
    expect(json['amountPaid'], 2500);
    expect(json.containsKey('notes'), isFalse);
  });

  test('DebtRecord.toJson omits amountPaid when nothing was paid', () {
    final debt = DebtRecord(
      customerId: 'c1',
      items: const [],
      totalAmount: 10000,
      debtDate: DateTime(2026, 11, 1),
    );
    expect(debt.toJson().containsKey('amountPaid'), isFalse);
  });

  test('DebtStatus.fromApi falls back to unpaid', () {
    expect(DebtStatus.fromApi('PAID'), DebtStatus.paid);
    expect(DebtStatus.fromApi('???'), DebtStatus.unpaid);
  });

  test('dates display in Indonesian', () {
    expect(DateFormatter.display(DateTime(2026, 1, 5)), '5 Jan 2026');
    expect(DateFormatter.display(DateTime(2026, 12, 31)), '31 Des 2026');
  });
}
