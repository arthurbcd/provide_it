import 'dart:async';

import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'ref.dart';

class ValueRef<T> extends Ref<T> {
  const ValueRef(
    this.initialValue, {
    this.debounce,
    this.throttle,
    super.key,
  });

  /// The initial value of this [ValueRef].
  final T initialValue;

  /// The duration a write must wait before applying. Resets on each write.
  /// If null, no debounce is applied.
  final Duration? debounce;

  /// The duration to wait between writes. Writes in intervals.
  /// If null, no throttle is applied.
  final Duration? throttle;

  @override
  Function? get create => null;

  @override
  Bind<T, ValueRef<T>> createBind() => ValueBind<T>();
}

class ValueBind<T> extends Bind<T, ValueRef<T>> {
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

/// Like a [ValueNotifier] but bounded to [ValueRef].
/// Ex:
/// ```dart
/// final count = context.value(0);
/// count.value = 1;
/// ```
extension ValueRecordExtension<T> on (T, void Function(T)) {
  /// The [ValueBind.read].
  T get value => $1;

  /// The [ValueBind.write].
  set value(T value) => $2(value);
}
