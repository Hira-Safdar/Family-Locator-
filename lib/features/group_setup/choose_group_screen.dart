import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/group_categories.dart';

class ChooseGroupScreen extends StatefulWidget {
  const ChooseGroupScreen({super.key});

  @override
  State<ChooseGroupScreen> createState() => _ChooseGroupScreenState();
}

class _ChooseGroupScreenState extends State<ChooseGroupScreen> {
  String? _selected;

  static const Map<String, IconData> _icons = {
    GroupCategories.friends: Icons.people_alt_outlined,
    GroupCategories.school: Icons.school_outlined,
    GroupCategories.office: Icons.work_outline,
    GroupCategories.travel: Icons.flight_takeoff,
    GroupCategories.custom: Icons.edit_outlined,
  };

  static const Map<String, String> _hints = {
    GroupCategories.friends: 'Family and friends in one place',
    GroupCategories.school: 'Classmates, trips and groups',
    GroupCategories.office: 'Colleagues and work teams',
    GroupCategories.travel: 'Trips, tours and travel buddies',
    GroupCategories.custom: 'Type your own group name',
  };

  void _continue() {
    final category = _selected ?? GroupCategories.custom;
    context.go('/create-group?category=$category');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Group')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'What kind of group are you creating?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  for (final category in GroupCategories.all)
                    _CategoryCard(
                      category: category,
                      icon: _icons[category] ?? Icons.group_outlined,
                      hint: _hints[category] ?? '',
                      selected: _selected == category,
                      onTap: () =>
                          setState(() => _selected = category),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: _selected == null ? null : _continue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final IconData icon;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: selected
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  child: Icon(
                    icon,
                    color: selected ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
