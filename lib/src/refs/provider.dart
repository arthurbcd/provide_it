import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework/framework.dart';

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

  @Deprecated('Use `context.value` instead.')
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
  late final T value = ref.create?.call(context) ?? ref.value as T;

  @override
  void initState() {
    if (ref.lazy == false) value;
    super.initState();
  }

  @override
  bool updateShouldNotify(Provider<T> oldRef) {
    if (ref.create != null) return false;

    final updateShouldNotify =
        ref.updateShouldNotify ?? (T prev, T next) => prev != next;

    return updateShouldNotify(oldRef.value as T, ref.value as T);
  }

  @override
  void dispose() {
    ref.dispose?.call(context, value);
    super.dispose();
  }

  @override
  T read(BuildContext context) => value;
}

typedef Create<T> = T Function(BuildContext context);
typedef Dispose<T> = void Function(BuildContext context, T value);
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);
