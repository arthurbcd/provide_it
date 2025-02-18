import 'package:flutter/widgets.dart';
import 'package:provide_it/src/refs/provider/provider.dart';

import '../../framework.dart';
import '../ref_widget.dart';

@Deprecated('Use `context` extensions instead.')
class MultiProvider extends RefWidget<void> {
  const MultiProvider({
    super.key,
    required this.providers,
    super.builder,
    super.child,
  });

  /// The providers to bind.
  final List<Provider> providers;

  @override
  RefState<void, MultiProvider> createState() => MultiProviderState();
}

class MultiProviderState extends RefState<void, MultiProvider> {
  @override
  void create() {}

  @override
  void read(BuildContext context) {}

  @override
  void bind(BuildContext context) {
    for (var provider in ref.providers) {
      provider.bind(context);
    }
  }
}
