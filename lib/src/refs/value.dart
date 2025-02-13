import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework/framework.dart';

extension ContextValue on BuildContext {
  (T, void Function(T)) value<T>(T initialValue, {Object? key}) {
    return ValueRef(initialValue, key: key).bind(this);
  }
}

extension ValuePair<T> on (T, void Function(T)) {
  T get value => $1;
  set value(T value) => $2(value);
}

@protected
class ValueRef<T> extends RefWidget<T> {
  const ValueRef(
    this.initialValue, {
    super.key,
    super.builder,
    super.child,
  });
  final T initialValue;

  @override
  (T, void Function(T)) bind(BuildContext context) => context.bind(this);

  @override
  RefState<T, ValueRef<T>> createState() => ValueRefState<T>();
}

class ValueRefState<T> extends RefState<T, ValueRef<T>> {
  late var value = ref.initialValue;

  void setValue(T value) {
    setState(() => this.value = value);
  }

  @override
  (T, void Function(T)) build(BuildContext context) => (value, setValue);

  @override
  T read(BuildContext context) => value;

  @override
  T? get debugValue => value;
}
