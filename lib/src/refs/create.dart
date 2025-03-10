import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework.dart';
import 'ref.dart';

class CreateRef<T> extends Ref<T> {
  const CreateRef(
    this.create, {
    this.dispose,
    super.key,
  });

  @override
  final T Function() create;

  /// How to dispose the created value.
  final void Function(T value)? dispose;

  @override
  T bind(BuildContext context) => context.bind(this);

  @override
  RefState<T, CreateRef<T>> createState() => CreateRefState<T>();
}

class CreateRefState<T> extends RefState<T, CreateRef<T>> {
  @override
  late T value = ref.create();

  @override
  void create() {
    value = ref.create();
    notifyObservers();
  }

  @override
  void dispose() {
    ref.dispose?.call(value);
    super.dispose();
  }
}
