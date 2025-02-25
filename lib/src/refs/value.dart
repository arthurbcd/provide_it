import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

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
  @override
  late T value = ref.initialValue;

  @override
  bool get shouldNotifySelf => true;

  void setValue(T value) {
    this.value = value;
    notifyDependents();
  }

  @override
  void create() {
    value = ref.initialValue;
  }

  @override
  (T, void Function(T)) bind(BuildContext context) => (value, setValue);

  @override
  T read() => value;
}

extension ValueRecordExtension<T> on (T, void Function(T)) {
  T get value => $1;
  set value(T value) => $2(value);
}
