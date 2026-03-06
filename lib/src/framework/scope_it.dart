part of '../framework.dart';

class ScopeIt extends InheritedElement with BindIt, InheritIt, WatchIt, ReadIt {
  ScopeIt(super.widget);

  static ScopeIt of(BuildContext context) {
    final scope = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(scope != null, 'You must set a `ProvideIt` above your app.');
    return scope as ScopeIt;
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  bool get isBuilding => switch (SchedulerBinding.instance.schedulerPhase) {
    SchedulerPhase.persistentCallbacks => true, // updating
    SchedulerPhase.idle => _frame == 0, // mounting
    _ => false,
  };

  _ReadIt get _readIt => (widget.scope ?? ReadIt.instance) as _ReadIt;

  @override
  void mount(Element? parent, Object? newSlot) {
    final scope = _readIt._scope ??= this;
    assert(
      scope != this || parent == null || Navigator.maybeOf(parent) == null,
      'The root `ProvideIt` widget must be above your app. ',
    );

    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    if (_readIt._scope == this) {
      _readIt._scope = null;
    }
    super.unmount();
  }

  /// Restart [ProvideIt] subtree and all its dependencies.
  void restart() {
    _restartKey = UniqueKey();
    markNeedsBuild();
  }

  Key? _restartKey;

  /// The future of all [isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future<void>>[];

    void isReady(InheritedState state) {
      if (state.isReady() case Future<void> future) {
        futures.add(future);
      }
    }

    _inheritedCache.forEach((_, cache) => cache.forEach(isReady));

    if (futures.isNotEmpty) {
      return Future.wait(futures, eagerError: true).then((_) {});
    }
  }

  /// The future when a [InheritedState] is ready to be [read] synchronously.
  @override
  FutureOr<void> isReady<T>({BuildContext? context}) {
    final state = getInheritedState<T>(context: context);
    assert(state != null || null is T, 'InheritedProvider<$T> not found.');

    if (state?.isReady() case Future<void> future) {
      return future.then((_) {});
    }
  }

  @override
  T read<T>({BuildContext? context}) {
    final value = readAsync<T>(context: context);

    switch (value) {
      case T():
        return value;
      case Future<T>():
        if (null is T) return null as T;
        throw LoadingProvideException('$T is loading');
    }
  }

  @override
  FutureOr<T> readAsync<T>({BuildContext? context, String? type}) {
    final state = getInheritedState<T>(context: context, type: type);

    switch (state?.read()) {
      case T value:
        return value;
      case Future future:
        return future.then((it) => it as T);
    }

    throw MissingProviderException('$type not found.');
  }

  @override
  void reassemble() {
    _reassembledFrame = _frame;
    super.reassemble();
  }

  int? _reassembledFrame;

  @override
  Widget build() {
    return Builder(
      key: _restartKey,
      builder: (context) {
        try {
          // we provide the providers to the tree.
          widget.provide?.call(context);
        } catch (error, stackTrace) {
          return widget.errorBuilder(context, error, stackTrace);
        }

        // we use `context.useFuture` hook to wait for all async binds.
        final snapshot = context.useFuture(allReady, key: _reassembledFrame);

        // if `allReady` is void (ready), we return child (super.build).
        switch (snapshot) {
          case AsyncSnapshot(connectionState: ConnectionState.waiting):
            return widget.loadingBuilder(context);
          case AsyncSnapshot(:final error?, :final stackTrace?):
            return widget.errorBuilder(context, error, stackTrace);
          default:
            return widget.child;
        }
      },
    );
  }
}
