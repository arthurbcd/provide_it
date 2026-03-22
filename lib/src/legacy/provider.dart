part of '../legacy.dart';

@Deprecated('Use `context.provide` instead.')
class Provider<T> extends ProviderWidget<T> {
  const Provider({
    super.key,
    super.lazy = true,
    this.create,
    this.dispose,
    super.builder,
    super.child,
  }) : value = null,
       updateShouldNotify = null;

  final Create<T>? create;
  final Dispose<T>? dispose;

  @Deprecated('Use `context.provideValue` instead.')
  const Provider.value({
    super.key,
    required T this.value,
    this.updateShouldNotify,
    super.builder,
    super.child,
  }) : create = null,
       dispose = null;

  @protected
  final T? value;

  /// Whether to notify dependents when the value changes.
  /// Defaults to `(T prev, T next) => prev != next`.
  final UpdateShouldNotify<T>? updateShouldNotify;

  @Deprecated('Use `context.read/watch` instead.')
  static T of<T>(BuildContext context, {bool listen = true}) {
    return listen ? context.watch<T>() : context.read<T>();
  }

  @override
  InheritedState<T, Provider<T>> createState() => _ProviderState<T>();
}

class _ProviderState<T> extends InheritedState<T, Provider<T>> {
  @override
  String get debugLabel => 'LegacyProvider<$T>';

  T? _value;
  bool _created = false;

  void _create() {
    _value = provider.create?.call(context) ?? provider.value;
    _created = true;
  }

  @override
  void updated(covariant Provider<T> oldProvider) {
    if (provider.value case var value?) {
      _value = value;
      if (_updateShouldNotify(oldProvider)) {
        notifyDependents();
      }
    }
    super.updated(oldProvider);
  }

  bool _updateShouldNotify(Provider<T> oldProvider) {
    if ((oldProvider.value, provider.value) case (var prev?, var next?)) {
      return provider.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    return oldProvider.value != provider.value;
  }

  @override
  void dispose() {
    if (_value case T value when _created) {
      provider.dispose?.call(context, value);
    }
    super.dispose();
  }

  @override
  void isReady() {}

  @override
  T read() {
    if (!_created) _create();
    return _value as T;
  }
}
