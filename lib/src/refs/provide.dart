import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework/framework.dart';
import 'value.dart';

@Deprecated('Use `context.provide` instead.')
typedef Provider<T> = ProvideRef<T>;
typedef Create<T> = T Function(BuildContext context);
typedef Dispose<T> = void Function(BuildContext context, T value);

extension ContextProvide on BuildContext {
  T provide<T>(Create<T> create, {Dispose<T>? dispose, Object? key}) {
    return ProvideRef<T>(create, dispose: dispose, key: key).bind(this);
  }
}

class ProvideRef<T> extends RefWidget<T> {
  const ProvideRef(
    this.create, {
    this.dispose,
    this.lazy,
    super.key,
    super.child,
    super.builder,
  });

  /// Whether to create the value only when it's first called.
  final bool? lazy;

  /// How to create the value.
  final Create<T> create;

  /// How to dispose the value.
  final Dispose<T>? dispose;

  @Deprecated('Use `context.value` instead.')
  static ValueRef<T> value<T>(
    T initialValue, {
    Key? key,
    TransitionBuilder? builder,
    Widget? child,
  }) {
    return ValueRef(
      initialValue,
      key: key,
      builder: builder,
      child: child,
    );
  }

  @Deprecated('Use `context.read/watch` instead.')
  static T of<T>(BuildContext context, {bool listen = true, Object? key}) {
    return listen ? context.watch(key: key) : context.read(key: key);
  }

  @override
  T bind(BuildContext context) => context.bind(this);

  @override
  RefState<T, ProvideRef<T>> createState() => ProvideState<T>();
}

class ProvideState<T> extends RefState<T, ProvideRef<T>> {
  late final T value = ref.create(context);

  void listener() => setState(() {});

  @override
  void initState() {
    if (value case Listenable value) value.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    ref.dispose?.call(context, value);
    if (value case Listenable value) value.removeListener(listener);
    if (value case ChangeNotifier value) value.dispose();
    super.dispose();
  }

  @override
  T build(BuildContext context) => value;

  @override
  T read(BuildContext context) => value;

  @override
  T get debugValue => value;
}
