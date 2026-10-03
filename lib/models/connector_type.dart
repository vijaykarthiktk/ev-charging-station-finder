/// Physical connector standards a plug or vehicle supports.
enum ConnectorType {
  ccs2,
  chademo,
  type2,
}

extension ConnectorTypeX on ConnectorType {
  /// Stable key for JSON round-trips.
  String get label => switch (this) {
        ConnectorType.ccs2 => 'CCS2',
        ConnectorType.chademo => 'CHAdeMO',
        ConnectorType.type2 => 'Type 2',
      };

  static ConnectorType fromLabel(String label) =>
      ConnectorType.values.firstWhere((c) => c.label == label,
          orElse: () => ConnectorType.type2);
}
