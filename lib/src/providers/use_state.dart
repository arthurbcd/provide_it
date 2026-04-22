import '../framework.dart';

extension ContextUseState on BuildContext {
  /// Returns a [Record] of a stateful [T] value and its setter.
  /// - [initialValue] is the initial value.
  ///
  /// Example:
  /// ```dart
  /// final (count, setCount) = context.useState(0);
  /// ```
  (T, void Function(T)) useState<T>(T initialValue, {Object? key}) {
    return bind(_UseState(initialValue, key: key)) as (T, void Function(T));
  }
}

class _UseState<T> extends HookProvider<Record> {
  const _UseState(this.initialValue, {super.key});
  final T initialValue;

  @override
  _UseStateState<T> createState() => _UseStateState<T>();
}

class _UseStateState<T> extends HookState<Record, _UseState<T>> {
  @override
  String get debugLabel => 'useState<$T>';

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
