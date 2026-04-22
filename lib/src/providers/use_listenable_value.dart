import '../framework.dart';

extension ContextUseListenable on BuildContext {
  /// Listens to an already created [Listenable] and returns it.
  @Deprecated('Use Listenable.watch() instead.')
  T useListenableValue<T extends Listenable>(T value) {
    return value.watch(this);
  }
}

extension ListenableHooks<T extends Listenable> on T {
  /// Rebuilds on [Listenable] changes and returns itself.
  T watch(BuildContext context) {
    context.bind(_UseListenableValue(this));
    return this;
  }

  S select<S>(BuildContext context, S Function(T value) selector) {
    context.bind(_UseListenableSelected(this, selector));
    return selector(this);
  }

  /// Listens to this [Listenable] and calls [listener] on changes.
  void listen(BuildContext context, void listener(T value)) {
    context.bind(_UseListenableValue(this, listener));
  }

  /// Listens to this [Listenable] and calls [listener] on selected changes.
  void listenSelected<R>(
    BuildContext context,
    R Function(T value) selector,
    void listener(R prev, R next),
  ) {
    context.bind(_UseListenableSelected(this, selector, listener));
  }
}

extension ValueListenableWatch<V extends ValueListenable<T>, T> on V {
  /// Rebuilds on [ValueListenable] changes and returns its [value].
  T watch(BuildContext context) {
    context.bind(_UseListenableValue(this));
    return value;
  }

  S select<S>(BuildContext context, S Function(T value) selector) {
    context.bind(_UseListenableSelected(this, (l) => selector(l.value)));
    return selector(value);
  }

  /// Listens to this [ValueListenable.value] and calls [listener] on changes.
  void listen(BuildContext context, void listener(T value)) {
    context.bind(_UseListenableValue(this, (l) => listener(l.value)));
  }

  /// Listens to this [ValueListenable.value] and calls [listener] on selected changes.
  void listenSelected<R>(
    BuildContext context,
    R Function(T value) selector,
    void listener(R prev, R next),
  ) {
    context.bind(
      _UseListenableSelected(this, (l) => selector(l.value), listener),
    );
  }
}

class _UseListenableValue<T extends Listenable> extends HookProvider<T> {
  const _UseListenableValue(this.value, [this.listener]);
  final T value;
  final void Function(T value)? listener;

  @override
  _UseListenableValueState<T> createState() => _UseListenableValueState();
}

class _UseListenableSelected<T extends Listenable, R> extends HookProvider<T> {
  const _UseListenableSelected(this.value, this.selector, [this.listener]);
  final T value;
  final R Function(T value) selector;
  final void Function(R prev, R next)? listener;

  @override
  _UseListenableSelectedState<T, R> createState() =>
      _UseListenableSelectedState();
}

class _UseListenableValueState<T extends Listenable>
    extends _HookState<T, _UseListenableValue<T>> {
  @override
  String get debugLabel => 'useListenableValue<$T>';

  @override
  void initState() {
    super.initState();
    listenable = provider.value;
  }

  @override
  void listener() {
    provider.listener != null
        ? provider.listener!(provider.value)
        : setState(() {});
  }

  @override
  void didUpdateProvider(covariant _UseListenableValue<T> oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (oldProvider.value != provider.value) {
      listenable = provider.value;
    }
  }
}

class _UseListenableSelectedState<T extends Listenable, R>
    extends _HookState<T, _UseListenableSelected<T, R>> {
  @override
  String get debugLabel => 'useListenableSelected<$T, $R>';

  late R _prev;

  @override
  void initState() {
    super.initState();
    listenable = provider.value;
    _prev = provider.selector(provider.value);
  }

  @override
  void listener() {
    final next = provider.selector(provider.value);

    if (!ProvideIt.equals(_prev, next)) {
      if (provider.listener case final listener?) {
        listener(_prev, next);
      } else {
        setState(() {});
      }
      _prev = next;
    }
  }

  @override
  void didUpdateProvider(covariant _UseListenableSelected<T, R> oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (oldProvider.value != provider.value) {
      listenable = provider.value;
      _prev = provider.selector(provider.value);
    }
  }
}

abstract class _HookState<T extends Listenable, P extends HookProvider<T>>
    extends HookState<T, P> {
  T? _listenable;

  set listenable(T newListenable) {
    _listenable?.removeListener(listener);
    _listenable = newListenable..addListener(listener);
  }

  T get listenable => _listenable!;

  void listener() => setState(() {});

  @override
  void activate() {
    _listenable?.addListener(listener);
    super.activate();
  }

  @override
  void deactivate() {
    _listenable?.removeListener(listener);
    super.deactivate();
  }

  @override
  T build(BuildContext context) {
    return listenable;
  }
}
