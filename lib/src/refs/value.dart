import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'ref.dart';

class ValueRef<T> extends Ref<T> {
  const ValueRef(
    this.initialValue, {
    super.key,
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
  void create() {
    value = ref.initialValue;
  }

  @override
  (T, void Function(T)) bind(BuildContext context) {
    return (watch(context), setValue);
  }

  @override
  T read(BuildContext context) => value;

  @override
  T get debugValue => value;
}

extension ValueRecordExtension<T> on (T, void Function(T)) {
  T get value => $1;
  set value(T value) => $2(value);
}
