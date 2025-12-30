import 'package:flutter/material.dart';
import 'package:cabsudapp/reuse/theme.dart';

class LuxuryDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;

  const LuxuryDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.payment,
            color: AppTheme.primaryGold,
          ),
          labelStyle: TextStyle(
            color: AppTheme.offWhite.withOpacity(0.8),
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppTheme.primaryGold,
            fontSize: 14,
          ),
        ),
        dropdownColor: AppTheme.charcoal,  // Dark dropdown background
        iconEnabledColor: AppTheme.primaryGold,
        // FIXED: White text in dropdown
        style: const TextStyle(
          color: AppTheme.softWhite,  // White text
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
