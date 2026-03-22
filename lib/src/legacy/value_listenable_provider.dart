part of '../legacy.dart';

@Deprecated('Use `context.provideValue` instead.')
class ValueListenableProvider<T> extends ProviderWidget<T> {
  /// Creates a [ValueListenable] provider that exposes [ValueListenable.value].
  const ValueListenableProvider.value({
    super.key,
    required ValueListenable<T> value,
    this.updateShouldNotify,
    super.builder,
    super.child,
  }) : _valueListenable = value;

  final ValueListenable<T> _valueListenable;
  final UpdateShouldNotify<T>? updateShouldNotify;

  @override
  InheritedState<T, ProviderWidget<T>> createState() =>
      ValueListenableProviderState<T>();
}

class ValueListenableProviderState<T>
    extends InheritedState<T, ValueListenableProvider<T>> {
  @override
  String get debugLabel => 'ValueListenableProvider<$T>';

  T? _previousValue;

  void _listener() {
    final newValue = provider._valueListenable.value;

    if (provider.updateShouldNotify case var test?) {
      if (_previousValue is T && test(_previousValue as T, newValue)) {
        _previousValue = newValue;
        notifyDependents();
      }
    } else {
      _previousValue = newValue;
      notifyDependents();
    }
  }

  @override
  void updated(covariant ValueListenableProvider<T> oldProvider) {
    if (provider._valueListenable != oldProvider._valueListenable) {
      oldProvider._valueListenable.removeListener(_listener);
      provider._valueListenable.addListener(_listener);
    }
    super.updated(oldProvider);
  }

  @override
  void initState() {
    super.initState();
    provider._valueListenable.addListener(_listener);
  }

  @override
  void dispose() {
    provider._valueListenable.removeListener(_listener);
    super.dispose();
  }

  @override
  void isReady() {}

  @override
  T read() {
    return provider._valueListenable.value;
  }
}
