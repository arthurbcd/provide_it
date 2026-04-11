import 'package:provide_it/src/framework.dart';

extension ContextProvide on BuildContext {
  /// Provides [T] using [create].
  void provide<T>(
    T Function() create, {
    void dispose(T value)?,
    bool lazy = true,
    Object? key,
  }) {
    bind(_Provide(key: key, create, dispose: dispose, lazy: lazy));
  }
}

class _Provide<T> extends InheritedProvider<T> {
  const _Provide(this.create, {this.dispose, super.lazy, super.key});
  final T Function() create;
  final void Function(T value)? dispose;

  @override
  InheritedState<T, _Provide<T>> createState() => _ProvideState();
}

class _ProvideState<T> extends InheritedState<T, _Provide<T>> {
  @override
  String get debugLabel => 'provide<$T>';

  T? _value;
  bool _created = false;

  void _create() {
    _created = true;
    _value = provider.create();
  }

  @override
  void dispose() {
    if (_value case T value when _created) {
      provider.dispose?.call(value);
    }
    super.dispose();
  }

  @override
  void isReady() {}

  @override
  T read() {
    if (!_created) {
      _create();
    }

    return _value as T;
  }
}
