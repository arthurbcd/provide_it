part of '../framework.dart';

class ProvideItElement extends InheritedElement {
  ProvideItElement(ProvideIt super.widget) {
    // attach scope to the widget tree.
    scope._element = this;
    scope.watchers.addAll(widget.additionalWatchers);
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;
  late final scope = (widget.scope ?? ReadIt.instance) as ProvideItScope;
  bool _reassembled = false;

  @protected
  Injector<I> injector<I>(Function create) {
    return Injector<I>(
      create,
      parameters: widget.parameters,
      locator: (p) => widget.locator?.call(p) ?? scope.readAsync(type: p.type),
    );
  }

  @override
  void reassemble() {
    for (final state in scope.states) {
      state.reassemble();
    }
    super.reassemble();
    _reassembled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _reassembled = false);
  }

  @override
  void removeDependent(Element dependent) {
    scope._tree[dependent]?.values.forEach((state) => state.deactivate());

    void dispose() {
      // binds
      scope._treeIndex.remove(dependent);
      scope._tree.remove(dependent)?.values.forEach((state) => state.dispose());

      // dependencies
      scope._dependencyIndex.remove(dependent);
      scope._dependencies
          .remove(dependent)
          ?.forEach((s) => s.removeDependent(dependent));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been displaced from the tree.
      // if it's still mounted, we reactivate it.
      dependent.mounted
          ? scope._tree[dependent]?.values.forEach((state) => state.activate())
          : dispose();
    });

    super.removeDependent(dependent);
  }

  @override
  Widget build() {
    // we bind the provided states to the tree.
    widget.provide?.call(this);

    // we use [FutureRef] a.k.a `context.future` to wait for all async states.
    final snapshot = future(allReady);

    // if `allReady` is void (ready), we immediately return `super.build`.
    return snapshot.maybeWhen(
      loading: () => widget.loadingBuilder(this),
      error: (e, s) => widget.errorBuilder(this, e, s),
      orElse: super.build,
    );
  }
}

extension on BuildContext {
  /// Stablishes a dependency between this `context` and [RefState].
  ///
  /// When unmounted, [RefState.removeDependent] will be called for each
  /// state dependency that this `context` depends on.
  void dependOnRefState(RefState state, String method, [String? useInstead]) {
    assert(
      this is Element && debugDoingBuild,
      '$method() should be called within the build(). ${useInstead ?? ''}',
    );
    final ProvideItScope scope = state._scope;

    // we depend so we can get notified by [removeDependent].
    dependOnInheritedElement(scope._element!);

    // we register the dependent so we can remove it when unmounted.
    final dependencies = scope._dependencies[this as Element] ??= {};
    dependencies.add(state);
  }
}
