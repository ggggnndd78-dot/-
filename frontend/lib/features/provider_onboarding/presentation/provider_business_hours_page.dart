import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class ProviderBusinessHoursPage extends ConsumerStatefulWidget {
  const ProviderBusinessHoursPage({super.key});

  @override
  ConsumerState<ProviderBusinessHoursPage> createState() =>
      _ProviderBusinessHoursPageState();
}

class _ProviderBusinessHoursPageState
    extends ConsumerState<ProviderBusinessHoursPage> {
  final _items = List.generate(
      7,
      (index) => {
            'day_of_week': index,
            'open_time': index == 5 ? null : '09:00',
            'close_time': index == 5 ? null : '18:00',
            'is_closed': index == 5,
          });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    const names = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return AppScaffold(
      title: 'ساعات العمل',
      child: Column(children: [
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Text(names[index])),
                      Switch(
                        value: !(item['is_closed'] as bool),
                        onChanged: (v) {
                          setState(() {
                            item['is_closed'] = !v;
                            item['open_time'] = v ? '09:00' : null;
                            item['close_time'] = v ? '18:00' : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        AppButton(
            text: 'حفظ ومتابعة',
            isLoading: state.loading,
            onPressed: () async {
              final items = _items
                  .map((e) => {
                        'dayOfWeek': e['day_of_week'],
                        'openTime': e['open_time'],
                        'closeTime': e['close_time'],
                        'isClosed': e['is_closed'],
                      })
                  .toList();
              final ok = await ref
                  .read(providerOnboardingControllerProvider.notifier)
                  .saveBusinessHours(items);
              if (!context.mounted) return;
              if (ok) {
                context.go(RouteNames.providerDocuments);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ref
                            .read(providerOnboardingControllerProvider)
                            .errorMessage ??
                        'تعذر حفظ ساعات العمل')));
              }
            })
      ]),
    );
  }
}
