import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../../framework.dart';
import '../ref_widget.dart';

@Deprecated('Use `context.provide` with `ChangeNotifierWatcher` instead.')
typedef ChangeNotifierProvider<T extends ChangeNotifier> = Provider<T>;

@Deprecated('Use `context.provide` with `ListenableWatcher` instead.')
typedef ListenableProvider<T extends Listenable> = Provider<T>;

@Deprecated('Use `context.provide` instead.')
class Provider<T> extends RefWidget<T> {
  const Provider({
    super.key,
    this.create,
    this.lazy,
    super.dispose,
    super.builder,
    super.child,
  })  : value = null,
        updateShouldNotify = null;

  /// Whether to create the value only when it's first called.
  final bool? lazy;

  @override
  final Create<T>? create;

  @Deprecated('Use `context.provideValue` instead.')
  const Provider.value({
    super.key,
    this.value,
    this.updateShouldNotify,
    super.builder,
    super.child,
  })  : create = null,
        lazy = null;

  /// An already created [value].
  final T? value;

  /// Whether to notify dependents when the value changes.
  /// Defaults to `(T prev, T next) => prev != next`.
  final UpdateShouldNotify<T>? updateShouldNotify;

  @Deprecated('Use `context.read/watch` instead.')
  static T of<T>(BuildContext context, {bool listen = true, Object? key}) {
    return listen ? context.watch(key: key) : context.read(key: key);
  }

  @override
  RefState<T, Provider<T>> createState() => ProviderState<T>();
}

class ProviderState<T> extends RefState<T, Provider<T>> {
  bool _created = false;

  @override
  void initState() {
    if (ref.lazy == false) _create();
    super.initState();
  }

  void _create() {
    value = ref.create != null ? ref.create!(context) : ref.value as T;

    _created = true;
    notifyObservers();
  }

  @override
  bool updateShouldNotify(Provider<T> oldRef) {
    bool didChange = oldRef.value != ref.value;

    if ((oldRef.value, ref.value) case (var prev?, var next?)) {
      didChange = ref.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    if (didChange) {
      _create();
    }

    return didChange;
  }

  @override
  T read() {
    if (!_created) _create();
    return super.read();
  }

  @override
  T? value;
}

typedef Create<T> = T Function(BuildContext context);
typedef Dispose<T> = void Function(BuildContext context, T value);
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);
