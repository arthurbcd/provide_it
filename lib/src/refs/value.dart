import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework.dart';
import 'ref.dart';

class ValueRef<T> extends Ref<T> {
  const ValueRef(
    this.initialValue, {
    this.debounce,
    this.throttle,
    super.key,
  });
  final T initialValue;

  /// The duration a write must wait before applying. Resets on each write.
  /// If null, no debounce is applied.
  final Duration? debounce;

  /// The duration to wait between writes. Writes in intervals.
  /// If null, no throttle is applied.
  final Duration? throttle;

  @override
  Function? get create => null;

  /// Writes a new [value] and notify all observers.
  ///
  /// - [ValueRef] must be bound to a [BuildContext].
  /// To bind a [ValueRef] use [watch].
  void write(BuildContext context, T value) {
    final state = context.getRefStateOfType<T>(key: this) as ValueRefState<T>;
    state.write(value);
  }

  (T, void Function(T)) watch(BuildContext context) {
    return bindOf(context).watch(context) as (T, void Function(T));
  }

  @override
  RefState<T, ValueRef<T>> createState() => ValueRefState<T>();
}

class ValueRefState<T> extends RefState<T, ValueRef<T>> {
  Timer? _debounceTimer, _throttleTimer;

  @override
  late T? value = ref.initialValue;

  @protected
  void write(T newValue) {
    if (ref.debounce == null) return _throttle(newValue);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(ref.debounce!, () => _throttle(newValue));
  }

  void _throttle(T newValue) {
    if (ref.throttle == null) return _write(newValue);

    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(ref.throttle!, () {});
    _write(newValue);
  }

  void _write(T newValue) {
    value = newValue;
    notifyObservers();
  }

  @override
  (T, void Function(T)) watch(BuildContext context) {
    super.watch(context);

    return (read(), write);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}

extension ValueRecordExtension<T> on (T, void Function(T)) {
  T get value => $1;
  set value(T value) => $2(value);
}
