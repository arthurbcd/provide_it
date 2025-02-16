import 'package:flutter/widgets.dart';

import '../framework/framework.dart';
import '../injector/injector.dart';

class ProvideRef<T> extends Ref<T> {
  const ProvideRef(
    this.create, {
    this.dispose,
    this.lazy = false,
    this.parameters,
    super.key,
  });

  /// How to create the value.
  final Function create;

  /// How to dispose the value.
  final void Function(T value)? dispose;

  /// The [Injector.parameters] to pass to [create].
  final Map<String, dynamic>? parameters;

  /// Whether to create the value only when it's first called.
  final bool lazy;

  @override
  RefState<T, ProvideRef<T>> createState() => ProvideRefState<T>();
}

class ProvideRefState<T> extends RefState<T, ProvideRef<T>> {
  late final injector = Injector<T>(ref.create, parameters: ref.parameters);
  late final T value = injector();

  @override
  String get type => injector.type;

  @override
  void initState() {
    if (!ref.lazy) value;
    super.initState();
  }

  @override
  void dispose() {
    (ref.dispose ?? tryDispose)(value);
    super.dispose();
  }

  @override
  T read(BuildContext context) => value;

  @override
  String get debugLabel =>
      'context.provide${ref.lazy ? 'Lazy' : ''}<${injector.type}>';
}
