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
    this.dispose,
    this.lazy,
    super.builder,
    super.child,
  })  : value = null,
        updateShouldNotify = null;

  /// Whether to create the value only when it's first called.
  final bool? lazy;

  /// How to create the value.
  final Create<T>? create;

  /// How to dispose the value.
  final Dispose<T>? dispose;

  @Deprecated('Use `context.provideValue` instead.')
  const Provider.value({
    super.key,
    this.value,
    this.updateShouldNotify,
    super.builder,
    super.child,
  })  : create = null,
        lazy = null,
        dispose = null;

  /// The value to provide.
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
    if (ref.lazy == false) create();
    super.initState();
  }

  @override
  void create() {
    final value = ref.create != null ? ref.create!(context) : ref.value as T;
    write(value);
    _created = true;
  }

  @override
  bool updateShouldNotify(Provider<T> oldRef) {
    var didChange = oldRef.value != ref.value;

    if ((oldRef.value, ref.value) case (var prev?, var next?)) {
      didChange = ref.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    if (didChange) {
      create();
    }

    return didChange;
  }

  @override
  void dispose() {
    if (value != null) {
      ref.dispose?.call(context, value as T);
    }
    super.dispose();
  }

  @override
  T read() {
    if (!_created) create();
    return super.read();
  }

  @override
  T? value;
}

typedef Create<T> = T Function(BuildContext context);
typedef Dispose<T> = void Function(BuildContext context, T value);
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);
