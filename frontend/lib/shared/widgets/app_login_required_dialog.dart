import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:go_router/go_router.dart';

Future<void> showAppLoginRequiredDialog(
  BuildContext context, {
  String? nextRoute,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('auth.loginRequiredForAction')),
      content: Text(context.tr('auth.guestModeNotice')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('auth.continueBrowsing')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go(RouteNames.register);
          },
          child: Text(context.tr('auth.create_account')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            final next = nextRoute == null || nextRoute.isEmpty
                ? ''
                : '?next=${Uri.encodeComponent(nextRoute)}';
            context.go('${RouteNames.login}$next');
          },
          child: Text(context.tr('auth.login')),
        ),
      ],
    ),
  );
}
