import '../framework.dart';

extension ContextUse on BuildContext {
  /// Provides [create] locally to this [BuildContext].
  ///
  /// You can use the value directly.
  T use<T>(
    T create(), {
    void dispose(T value)?,
    Object? key,
  }) {
    return bind(_Hook<T>(
      create,
      dispose: dispose,
      key: key,
    ));
  }
}

class _Hook<T> extends HookProvider<T> {
  const _Hook(
    this.create, {
    this.dispose,
    super.key,
  });

  final T Function() create;
  final void Function(T value)? dispose;

  @override
  _HookState<T> createState() => _HookState();
}

class _HookState<T> extends HookState<T, _Hook<T>> {
  @override
  String get debugLabel => 'use<$T>';

  late final T value = provider.create();

  @override
  void dispose() {
    provider.dispose?.call(value);
    super.dispose();
  }

  @override
  T build(BuildContext context) {
    return value;
  }
}
