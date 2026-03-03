import 'dart:async';

import 'core.dart';
import 'framework.dart';

part 'legacy/consumer.dart';
part 'legacy/future_provider.dart';
part 'legacy/multi_provider.dart';
part 'legacy/provider.dart';
part 'legacy/provider_widget.dart';
part 'legacy/value_listenable_provider.dart';

typedef Create<T> = T Function(BuildContext context);
typedef Dispose<T> = void Function(BuildContext context, T value);
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

@Deprecated('Use `context.provide` with `ListenableWatcher` instead.')
typedef ChangeNotifierProvider<T extends ChangeNotifier> = Provider<T>;

@Deprecated('Use `context.provide` with `ListenableWatcher` instead.')
typedef ListenableProvider<T extends Listenable> = Provider<T>;
