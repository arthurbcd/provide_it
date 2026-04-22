import '../framework.dart';

extension ContextUseValueNotifier on BuildContext {
  /// Creates a [ValueNotifier] that is automatically disposed.
  ValueNotifier<T> useValueNotifier<T>(T initialValue, {Object? key}) {
    return bind(_UseValueNotifier(initialValue, key: key));
  }
}

class _UseValueNotifier<T> extends HookProvider<ValueNotifier<T>> {
  const _UseValueNotifier(this.initialValue, {super.key});

  final T initialValue;

  @override
  _UseValueNotifierState<T> createState() => _UseValueNotifierState<T>();
}

class _UseValueNotifierState<T>
    extends HookState<ValueNotifier<T>, _UseValueNotifier<T>> {
  @override
  String get debugLabel => 'useValueNotifier<$T>';

  late final ValueNotifier<T> value = ValueNotifier<T>(provider.initialValue);

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  ValueNotifier<T> build(BuildContext context) {
    return value;
  }
}
