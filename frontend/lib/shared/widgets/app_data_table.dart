import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headingRowColor,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final WidgetStateProperty<Color?>? headingRowColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      tone: AppCardTone.elevated,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
          headingRowColor: headingRowColor ??
              WidgetStateProperty.all(
                AppColors.surfaceHigh.withValues(alpha: 0.92),
              ),
          dividerThickness: 1,
          dataTextStyle: Theme.of(context).textTheme.bodyMedium,
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
