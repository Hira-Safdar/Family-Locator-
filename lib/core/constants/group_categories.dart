class GroupCategories {
  const GroupCategories._();

  static const String friends = 'Friends';
  static const String school = 'School';
  static const String office = 'Office';
  static const String travel = 'Travel';
  static const String custom = 'Custom';

  static const List<String> all = [friends, school, office, travel, custom];

  static bool contains(String value) => all.contains(value);

  static String normalize(String? value) {
    if (value == null) return custom;
    for (final item in all) {
      if (item.toLowerCase() == value.trim().toLowerCase()) return item;
    }
    return custom;
  }
}
