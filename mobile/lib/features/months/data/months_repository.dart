import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

abstract interface class MonthsRepository {
  Future<List<MonthRow>> fetchYear({
    required int year,
    required String memberId,
  });
}

class MockMonthsRepository implements MonthsRepository {
  @override
  Future<List<MonthRow>> fetchYear({
    required int year,
    required String memberId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    const namesEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const namesOm = [
      'Amajjii', 'Guraandhala', 'Bitooteessa', 'Elbaa', 'Caamsa', 'Waxabajjii',
      'Adooleessa', 'Hagayya', 'Fuulbana', 'Onkololeessa', 'Sadaasa', 'Muddee',
    ];

    const states = <ContributionState>[
      ContributionState.paid,     // Jan
      ContributionState.paid,     // Feb
      ContributionState.unpaid,   // Mar
      ContributionState.paid,     // Apr
      ContributionState.paid,     // May
      ContributionState.unpaid,   // Jun
      ContributionState.paid,     // Jul
      ContributionState.waived,   // Aug
      ContributionState.paid,     // Sep
      ContributionState.paid,     // Oct
      ContributionState.unpaid,   // Nov
      ContributionState.unpaid,   // Dec
    ];

    final rows = <MonthRow>[];
    for (var i = 0; i < 12; i++) {
      final state = states[i];
      const due = 100.0;
      final paid = switch (state) {
        ContributionState.paid => 100.0,
        ContributionState.waived => 0.0,
        ContributionState.unpaid => 0.0,
        ContributionState.pending => 0.0,
        ContributionState.suspended => 0.0,
      };

      final penalty = switch (state) {
        ContributionState.unpaid when i < 6 => 20.0,
        _ => 0.0,
      };

      rows.add(MonthRow(
        period: DateTime(year, i + 1, 1),
        monthNameEn: namesEn[i],
        monthNameOm: namesOm[i],
        state: state,
        amountDue: due,
        amountPaid: paid,
        currency: 'ETB',
        penaltyAmount: penalty,
        paidAt: state == ContributionState.paid
            ? DateTime(year, i + 1, 5)
            : null,
      ),);
    }
    return rows;
  }
}