import 'package:cash_compass/state/finance_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget/harness.dart';

void main() {
  test('withdrawing reduces a goal balance, floored at zero', () async {
    final finance = FinanceProvider(FakePrefs());
    await finance.load();

    finance.addGoal(name: 'Trip', target: 1000, initialAmount: 300);
    final id = finance.goals.first.id;

    finance.withdrawFromGoal(id, 100);
    expect(finance.goals.first.current, 200);

    finance.withdrawFromGoal(id, 1000);
    expect(
      finance.goals.first.current,
      0,
      reason: 'a withdrawal larger than the balance floors at zero',
    );

    await finance.flush();
  });

  test('withdrawing does not clear a stamped completedAt', () async {
    final finance = FinanceProvider(FakePrefs());
    await finance.load();

    finance.addGoal(name: 'Buffer', target: 100);
    final id = finance.goals.first.id;
    finance.contributeToGoal(id, 100);
    expect(finance.goals.first.completedAt, isNotNull);

    finance.withdrawFromGoal(id, 50);
    expect(
      finance.goals.first.completedAt,
      isNotNull,
      reason: 'a goal that was once completed stays "completed" for badges',
    );

    await finance.flush();
  });

  test('a non-positive or non-finite amount is ignored', () async {
    final finance = FinanceProvider(FakePrefs());
    await finance.load();
    finance.addGoal(name: 'Trip', target: 1000, initialAmount: 300);
    final id = finance.goals.first.id;

    finance.withdrawFromGoal(id, 0);
    finance.withdrawFromGoal(id, -10);
    finance.withdrawFromGoal(id, double.nan);
    expect(finance.goals.first.current, 300);

    await finance.flush();
  });
}
