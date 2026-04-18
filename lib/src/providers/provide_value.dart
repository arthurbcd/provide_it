import '../framework.dart';

extension ContextProvideValue on BuildContext {
  /// Directly provides [value].
  T provideValue<T>(
    T value, {
    bool updateShouldNotify(T prev, T next)?, // prev != next
    Object? key,
  }) {
    bind(
      _ProvideValue(value, key: key, updateShouldNotify: updateShouldNotify),
    );

    return value;
  }
}

class _ProvideValue<T> extends InheritedProvider<T> {
  const _ProvideValue(this.value, {super.key, this.updateShouldNotify});

  final T value;
  final bool Function(T prev, T next)? updateShouldNotify;

  @override
  _ProvideValueState<T> createState() => _ProvideValueState<T>();
}

class _ProvideValueState<T> extends InheritedState<T, _ProvideValue<T>> {
  @override
  String get debugLabel => 'provideValue<$T>';

  @override
  void updated(covariant _ProvideValue<T> oldProvider) {
    if (provider.updateShouldNotify case final shouldNotify?) {
      if (shouldNotify(oldProvider.value, provider.value)) {
        notifyDependents();
      }
    } else if (oldProvider.value != provider.value) {
      notifyDependents();
    }
    super.updated(oldProvider);
  }

  @override
  void isReady() {}

  @override
  T read() {
    return provider.value;
  }
}
