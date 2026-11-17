import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds its child twice a second. Used for clocks and countdowns.
class TickBuilder extends StatefulWidget {
  const TickBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
