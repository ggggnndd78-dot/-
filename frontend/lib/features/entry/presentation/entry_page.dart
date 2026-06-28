import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/app/router/route_names.dart';

/// Kept only as a backward-compatible route.
/// The enterprise login flow must not expose account type shortcuts.
class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
