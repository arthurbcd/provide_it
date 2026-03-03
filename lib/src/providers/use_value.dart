import '../framework.dart';

extension ContextUseValue on BuildContext {
  /// Provides [T] value to this [BuildContext].
  /// - [initialValue] is the initial value.
  ///
  /// You can use the record to manage the value state.
  ValueRecord<T> useValue<T>(
    T initialValue, {
    Object? key,
  }) {
    return bind(_ValueHook(
      initialValue,
      key: key,
    )) as ValueRecord<T>;
  }
}

class _ValueHook<T> extends HookProvider<dynamic> {
  const _ValueHook(
    this.initialValue, {
    super.key,
  });
  final T initialValue;

  @override
  _ValueHookState<T> createState() => _ValueHookState<T>();
}

class _ValueHookState<T> extends HookState<dynamic, _ValueHook<T>> {
  @override
  String get debugLabel => 'useValue<$T>';

  late T value = provider.initialValue;

  void setValue(T newValue) {
    setState(() {
      value = newValue;
    });
  }

  @override
  (T, void Function(T)) build(BuildContext context) {
    return (value, setValue);
  }
}

typedef ValueRecord<T> = (T, void Function(T));

/// Like a [ValueNotifier] but bounded to [_ValueHook].
/// Ex:
/// ```dart
/// final counter = context.useValue(0);
/// final (count, setCount) = counter; // Destructuring
/// ```
/// Then you can get/set the value:
/// ```dart
/// counter.value = 1; // or setCount(1);
/// ```
extension ValueRecordExtension<T> on ValueRecord<T> {
  /// The [_ValueHookState.value].
  T get value => $1;

  /// The [_ValueHookState.setValue].
  set value(T value) => $2(value);
}
