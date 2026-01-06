import 'dart:async';

import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'ref.dart';

class UseValueRef<T> extends Ref<T> {
  const UseValueRef(
    this.initialValue, {
    this.debounce,
    this.throttle,
    super.key,
  });

  /// The initial value of this [UseValueRef].
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
  Bind<T, UseValueRef<T>> createBind() => UseValueBind<T>();
}

class UseValueBind<T> extends Bind<T, UseValueRef<T>> {
  Timer? _debounceTimer, _throttleTimer;

  @override
  late T? value = ref.initialValue;

  @protected
  void setValue(T newValue) {
    if (ref.debounce == null) return _throttle(newValue);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(ref.debounce!, () => _throttle(newValue));
  }

  void _throttle(T newValue) {
    if (ref.throttle == null) return _setValue(newValue);

    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(ref.throttle!, () {});
    _setValue(newValue);
  }

  void _setValue(T newValue) {
    value = newValue;
    notifyObservers();
  }

  @override
  (T, void Function(T)) watch(BuildContext context) {
    super.watch(context);

    return (read(), setValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}

/// Like a [ValueNotifier] but bounded to [UseValueRef].
/// Ex:
/// ```dart
/// final count = context.useValue(0);
/// ```
/// Then you can get/set the value:
/// ```dart
/// count.value = 1;
/// ```
extension ValueRecordExtension<T> on (T, void Function(T)) {
  /// The [UseValueBind.value].
  T get value => $1;

  /// The [UseValueBind.setValue].
  set value(T value) => $2(value);
}
