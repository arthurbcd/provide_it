part of '../framework.dart';

class ProvideItElement extends InheritedElement {
  ProvideItElement(super.widget);

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  @protected
  late final scope = switch (widget.scope) {
    null => !readIt.mounted ? ReadIt.instance : ReadIt.asNewInstance(),
    final scope => scope,
  } as ProvideItScope;

  bool _reassembled = false;

  @protected
  Injector<I> injector<I>(Function create) {
    return Injector<I>(
      create,
      parameters: widget.parameters,
      locator: (p) {
        return widget.locator?.call(p) ?? scope.readAsync<I?>(type: p.type);
      },
    );
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    if (scope._element != null) {
      throw StateError(
        'Scope already attached to: ${scope._element}. Cannot attach to $this.',
      );
    }
    if (scope == ReadIt.instance) {
      assert(
        parent == null || Navigator.maybeOf(parent) == null,
        'The root `ProvideIt` widget must be above your app. ',
      );
    }
    scope._element = this;
    super.mount(parent, newSlot);
  }

  @override
  void reassemble() {
    for (final bind in scope.binds) {
      bind.reassemble();
    }
    super.reassemble();
    _reassembled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _reassembled = false);
  }

  @override
  void removeDependent(Element dependent) {
    scope._tree[dependent]?.values.forEach((bind) => bind.deactivate());

    void dispose() {
      // binds
      scope._treeIndex.remove(dependent);
      scope._tree.remove(dependent)?.values.forEach((bind) => bind.dispose());

      // dependencies
      scope._dependencyIndex.remove(dependent);
      scope._dependencies
          .remove(dependent)
          ?.forEach((s) => s.removeDependent(dependent));
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been displaced from the tree.
      // if it's still mounted, we reactivate it.
      dependent.mounted
          ? scope._tree[dependent]?.values.forEach((bind) => bind.activate())
          : dispose();
    });

    super.removeDependent(dependent);
  }

  @override
  void unmount() {
    super.unmount();

    // we give a chance for binds to auto-dispose.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      assert(scope._tree.isEmpty, '${scope._tree.length} binds not disposed.');
      scope._element = null;
    });
  }

  @override
  Widget build() {
    // we bind the providers to the tree.
    widget.provide?.call(this);

    // we use [FutureRef] a.k.a `context.future` to wait for all async binds.
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
  /// Stablishes a dependency between this `context` and [bind].
  ///
  /// When disabled, [Bind.removeDependent] will be called for each
  /// bind dependency that this `context` depends on.
  void dependOnBind(Bind bind, String method, [String? instead]) {
    assert(
      debugDoingBuild,
      '$method() should be called within the build(). ${instead ?? ''}',
    );
    final ProvideItScope scope = bind._scope;

    // we depend so we can get notified by [Element.removeDependent].
    dependOnInheritedElement(scope._element!);

    // we register it to notify the depending binds [Bind.removeDependent].
    final dependencies = scope._dependencies[this as Element] ??= {};
    dependencies.add(bind);
  }
}
