import '../framework.dart';

extension ContextUse on BuildContext {
  /// Provides [create] locally to this [BuildContext].
  ///
  /// You can use the value directly.
  T use<T>(T create(), {void dispose(T value)?, Object? key}) {
    return bind(_Use<T>(create, dispose: dispose, key: key));
  }
}

class _Use<T> extends HookProvider<T> {
  const _Use(this.create, {this.dispose, super.key});

  final T Function() create;
  final void Function(T value)? dispose;

  @override
  _UseState<T> createState() => _UseState();
}

class _UseState<T> extends HookState<T, _Use<T>> {
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
