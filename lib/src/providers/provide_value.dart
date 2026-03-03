import '../framework.dart';

extension ContextProvideValue on BuildContext {
  /// Directly provides [value].
  T provideValue<T>(
    T value, {
    bool updateShouldNotify(T prev, T next)?, // prev != next
    Object? key,
  }) {
    bind(
      _ValueInherited(value, key: key, updateShouldNotify: updateShouldNotify),
    );

    return value;
  }
}

class _ValueInherited<T> extends InheritedProvider<T> {
  const _ValueInherited(this.value, {super.key, this.updateShouldNotify});

  /// An already created [value].
  final T value;

  /// Whether to notify dependents when the value changes.
  final bool Function(T prev, T next)? updateShouldNotify;

  @override
  _ValueInheritedState<T> createState() => _ValueInheritedState<T>();
}

class _ValueInheritedState<T> extends InheritedState<T, _ValueInherited<T>> {
  @override
  String get debugLabel => 'provideValue<$T>';

  @override
  void didUpdateProvider(covariant _ValueInherited<T> oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (provider.updateShouldNotify case final shouldNotify?) {
      if (shouldNotify(oldProvider.value, provider.value)) {
        notifyDependents();
      }
    } else if (oldProvider.value != provider.value) {
      notifyDependents();
    }
  }

  @override
  T read() {
    return provider.value;
  }
}
