import '../framework.dart';

extension ContextUseListenable on BuildContext {
  /// Creates and listens to the [Listenable] of [create] and returns it.
  /// Automatically disposes if it's a [ChangeNotifier].
  T useListenable<T extends Listenable>(T create(), {Object? key}) {
    return bind(_UseListenable(create, key: key));
  }

  /// Listens to an already created [Listenable] and returns it.
  @Deprecated('Use Listenable.watch() instead.')
  T useListenableValue<T extends Listenable>(T value, {Object? key}) {
    return value.watch(this, key: key);
  }
}

extension ListenableWatch<T extends Listenable> on T {
  /// Listens to this [Listenable] and returns its snapshot.
  T watch(BuildContext context, {Object? key}) {
    return context.bind(_UseListenableValue(this, key: key));
  }
}

extension ValueListenableWatch<T> on ValueListenable<T> {
  /// Listens to this [Listenable] and returns its snapshot.
  T watch(BuildContext context, {Object? key}) {
    return context.bind(_UseListenableValue(this, key: key)).value;
  }
}

class _UseListenable<T extends Listenable> extends HookProvider<T> {
  const _UseListenable(this.create, {super.key});
  final T Function() create;

  @override
  _UseListenableState<T> createState() => _UseListenableState<T>();
}

class _UseListenableValue<T extends Listenable> extends HookProvider<T> {
  const _UseListenableValue(this.value, {super.key});
  final T value;

  @override
  _UseListenableValueState<T> createState() => _UseListenableValueState<T>();
}

abstract class _ListenableState<T extends Listenable, P extends HookProvider<T>>
    extends HookState<T, P> {
  late T? _listenable;

  set listenable(T newListenable) {
    _listenable?.removeListener(_listener);
    _listenable = newListenable..addListener(_listener);
  }

  T get listenable => _listenable!;

  void _listener() => setState(() {});

  @override
  void activate() {
    _listenable?.addListener(_listener);
    super.activate();
  }

  @override
  void deactivate() {
    _listenable?.removeListener(_listener);
    super.deactivate();
  }

  @override
  T build(BuildContext context) => _listenable!;
}

class _UseListenableState<T extends Listenable>
    extends _ListenableState<T, _UseListenable<T>> {
  @override
  String get debugLabel => 'useListenable<$T>';

  @override
  void initState() {
    super.initState();
    listenable = provider.create();
  }

  @override
  void dispose() {
    if (listenable case ChangeNotifier notifier) {
      notifier.dispose();
    }
    super.dispose();
  }
}

class _UseListenableValueState<T extends Listenable>
    extends _ListenableState<T, _UseListenableValue<T>> {
  @override
  String get debugLabel => 'useListenableValue<$T>';

  @override
  void initState() {
    super.initState();
    listenable = provider.value;
  }

  @override
  void didUpdateProvider(covariant _UseListenableValue<T> oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (oldProvider.value != provider.value) {
      listenable = provider.value;
    }
  }
}
