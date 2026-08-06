/// Mirrors `com.abraar.homebase.finance.networth.NetWorthCategory` — the wire
/// value is the enum name, the label is what the UI shows.
enum NetWorthCategory {
  cash('CASH', 'Cash'),
  savings('SAVINGS', 'Savings'),
  investment('INVESTMENT', 'Investment'),
  pension('PENSION', 'Pension'),
  property('PROPERTY', 'Property'),
  other('OTHER', 'Other'),
  liability('LIABILITY', 'Liability');

  final String wireValue;
  final String label;

  const NetWorthCategory(this.wireValue, this.label);

  bool get isLiability => this == NetWorthCategory.liability;

  /// Falls back to [NetWorthCategory.other] for a value this build doesn't know
  /// about, so a newer server never breaks the list.
  static NetWorthCategory fromWire(String? value) {
    return NetWorthCategory.values.firstWhere(
      (c) => c.wireValue == value,
      orElse: () => NetWorthCategory.other,
    );
  }
}

class NetWorthAccount {
  final int id;
  final String name;
  final NetWorthCategory category;
  final double balance;
  final int sortOrder;
  final DateTime? updatedAt;

  const NetWorthAccount({
    required this.id,
    required this.name,
    required this.category,
    required this.balance,
    required this.sortOrder,
    this.updatedAt,
  });

  /// What this row contributes to net worth — a liability comes off the total.
  double get signedBalance => category.isLiability ? -balance : balance;

  factory NetWorthAccount.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as String?;
    return NetWorthAccount(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: NetWorthCategory.fromWire(json['category'] as String?),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
    );
  }

  static Map<String, dynamic> toRequestJson({
    required String name,
    required NetWorthCategory category,
    required double balance,
  }) {
    return {
      'name': name,
      'category': category.wireValue,
      'balance': balance,
    };
  }
}

class NetWorthCategoryTotal {
  final NetWorthCategory category;
  final String label;
  final double total;

  const NetWorthCategoryTotal({
    required this.category,
    required this.label,
    required this.total,
  });

  factory NetWorthCategoryTotal.fromJson(Map<String, dynamic> json) {
    final category = NetWorthCategory.fromWire(json['category'] as String?);
    return NetWorthCategoryTotal(
      category: category,
      label: json['label'] as String? ?? category.label,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NetWorthSummary {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final List<NetWorthCategoryTotal> categories;
  final List<NetWorthAccount> accounts;

  const NetWorthSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.categories,
    required this.accounts,
  });

  factory NetWorthSummary.fromJson(Map<String, dynamic> json) {
    return NetWorthSummary(
      totalAssets: (json['totalAssets'] as num?)?.toDouble() ?? 0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toDouble() ?? 0,
      categories: ((json['categories'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(NetWorthCategoryTotal.fromJson)
          .toList(),
      accounts: ((json['accounts'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(NetWorthAccount.fromJson)
          .toList(),
    );
  }
}
