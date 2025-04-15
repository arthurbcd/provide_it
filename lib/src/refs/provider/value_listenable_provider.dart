import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provide_it/provide_it.dart';

@Deprecated('Use `context.provideValue` instead.')
class ValueListenableProvider<T> extends Provider<T> {
  /// Creates a [ValueListenable] provider that exposes [ValueListenable.value].
  const ValueListenableProvider.value({
    super.key,
    required ValueListenable<T> value,
    super.updateShouldNotify,
    super.builder,
    super.child,
  })  : _valueListenable = value,
        super.value();

  final ValueListenable<T> _valueListenable;

  @override
  Bind<T, Provider<T>> createBind() => ValueListenableProviderState<T>();
}

class ValueListenableProviderState<T>
    extends Bind<T, ValueListenableProvider<T>> {
  T? _previousValue;

  @override
  void notifyObservers() {
    bool didChange = _previousValue != value;

    if ((_previousValue, ref.value) case (var prev?, var next?)) {
      didChange = ref.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    if (didChange) {
      _previousValue = ref._valueListenable.value;
      super.notifyObservers();
    }
  }

  @override
  void initBind() {
    super.initBind();
    _previousValue = ref._valueListenable.value;
    ref._valueListenable.addListener(notifyObservers);
  }

  @override
  void dispose() {
    ref._valueListenable.removeListener(notifyObservers);
    super.dispose();
  }

  @override
  T get value => ref._valueListenable.value;
}

extension ValueListenableBinder<T> on ValueListenable<T> {
  T watch(BuildContext context) => context.provideValue(this).value;
}
