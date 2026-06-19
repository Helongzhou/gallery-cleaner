enum ProcessAction {
  organized,
  pendingDelete,
}

extension ProcessActionX on ProcessAction {
  String get dbValue => name;

  static ProcessAction fromDb(String value) {
    return ProcessAction.values.firstWhere((e) => e.name == value);
  }
}
