part of '../framework.dart';

class ScopeIt extends InheritedScope with BindIt, InheritIt, DependIt, ReadIt {
  ScopeIt(super.widget);

  static ScopeIt of(BuildContext context) {
    final scope = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(scope != null, 'You must set a `ProvideIt` above your app.');
    return scope as ScopeIt;
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  _ReadIt get _readIt => (widget.scope ?? ReadIt.instance) as _ReadIt;

  @override
  void mount(Element? parent, Object? newSlot) {
    final scope = _readIt._scope ??= this;
    assert(
      this != scope || parent == null || Navigator.maybeOf(parent) == null,
      'The root `ProvideIt` widget must be above your app. ',
    );

    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    if (identical(_readIt._scope, this)) {
      _readIt._scope = null;
    }
    super.unmount();
  }

  /// The future of all [isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future<void>>[];

    void isReady(InheritedBind bind) {
      if (bind.isReady() case Future<void> future) {
        futures.add(future);
      }
    }

    _cache.forEach((_, cache) => cache.forEach(isReady));

    if (futures.isNotEmpty) {
      return Future.wait(futures, eagerError: true).then((_) {});
    }
  }

  /// The future when a [InheritedState] is ready to be [read] synchronously.
  @override
  FutureOr<void> isReady<T>({BuildContext? context}) {
    final state = getInheritedBind<T>(context: context);
    assert(state != null || null is T, 'InheritedProvider<$T> not found.');

    if (state?.isReady() case Future<void> future) {
      return future.then((_) {});
    }
  }

  @override
  T read<T>({BuildContext? context}) {
    if (readAsync<T>(context: context) case T value) return value;
    if (null is T) return null as T;
    throw ProviderNotReadyException('$T is loading');
  }

  @override
  FutureOr<T> readAsync<T>({BuildContext? context, String? type}) {
    final state = getInheritedBind<T>(context: context, type: type);

    return switch (state?.read()) {
      T value => value,
      Future future => future.then((it) => it as T),
      _ => throw ProviderNotFoundException('$type not found.'),
    };
  }

  @override
  Widget build() {
    switch (useFuture(widget.setup)) {
      case AsyncSnapshot(connectionState: ConnectionState.waiting):
        return widget.loadingBuilder(this);
      case AsyncSnapshot(:final error?, :final stackTrace?):
        return widget.errorBuilder(this, error, stackTrace);
    }

    try {
      widget.provide?.call(this);
    } catch (error, stackTrace) {
      return widget.errorBuilder(this, error, stackTrace);
    }

    switch (useFuture(allReady)) {
      case AsyncSnapshot(connectionState: ConnectionState.waiting):
        return widget.loadingBuilder(this);
      case AsyncSnapshot(:final error?, :final stackTrace?):
        return widget.errorBuilder(this, error, stackTrace);
    }

    return widget.child;
  }
}

class Node extends NodeBase with Bindings, Dependencies {
  Node(super.dependent);
}
