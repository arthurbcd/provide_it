import 'package:provide_it/src/refs/provider/provider.dart';
import 'package:provide_it/src/refs/ref.dart';

import '../../framework.dart';
import '../ref_widget.dart';

@Deprecated('Use `context.provide` instead.')
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
  Function? get create => null;

  @override
  RefState<void, MultiProvider> createState() => MultiProviderState();
}

class MultiProviderState extends RefState<void, MultiProvider> {
  void _bind() {
    for (var provider in ref.providers) {
      provider.bind(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateRef(MultiProvider oldRef) {
    super.didUpdateRef(oldRef);
    _bind();
  }

  @override
  void value;
}
