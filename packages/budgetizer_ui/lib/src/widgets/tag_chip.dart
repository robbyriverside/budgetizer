import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  final String? type;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.type,
    this.onDeleted,
    this.onTap,
  });

  Color _getTagColor(String? type) {
    if (type == null) return Colors.grey;
    switch (type) {
      case 'Vendor':
        // Yellow (Darker for readability against white text, or use black text?)
        // User requested Yellow. Standard Yellow (Colors.yellow) is hard to read with white text.
        // Using Amber or Yellow[700] often works better. Or use Black text.
        // Let's try Colors.yellowAccent[700] (darker yellow) or Colors.amber.
        return Colors.amber.shade700;
      case 'Market':
        return Colors.green; // Green
      case 'System':
        return Colors.lightBlue; // Light Blue
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTagColor(type);
    // Determine text color based on background lightness
    final isLight =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final iconColor = isLight ? Colors.black54 : Colors.white70;

    return InputChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      backgroundColor: color,
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 14, color: iconColor)
          : null,
      onDeleted: onDeleted,
      onPressed: onTap,
    );
  }
}
