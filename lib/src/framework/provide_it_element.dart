part of '../framework.dart';

class ProvideItElement extends InheritedElement {
  ProvideItElement(super.widget);

  static ProvideItElement of(BuildContext context) {
    final it = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(it != null, 'You must set a `ProvideIt` above your app.');
    return it as ProvideItElement;
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  @protected
  late final container =
      switch (widget.scope) {
            null => !readIt.mounted ? ReadIt.instance : ReadIt.asNewInstance(),
            final scope => scope,
          }
          as ProvideItContainer;

  bool get isBuilding => switch (SchedulerBinding.instance.schedulerPhase) {
    SchedulerPhase.persistentCallbacks => true, // updating
    SchedulerPhase.idle => _frame == 0, // mounting
    _ => false,
  };

  @protected
  Injector<I> injector<I>(Function create) {
    return Injector<I>(
      create,
      parameters: widget.parameters,
      locator: (p) {
        return widget.locator?.call(p) ?? container.readAsync<I?>(type: p.type);
      },
    );
  }

  @protected
  VoidCallback tryWatch<W>(InheritedState state) {
    final value = state.read();
    for (final watcher in widget.watchers.whereType<Watcher<W>>()) {
      if (watcher.canWatch(value)) {
        watcher.init(value as W, state.notifyDependents);
        return () {
          watcher.cancel(value, state.notifyDependents);
          watcher.dispose(value);
        };
      }
    }

    return _doNothing;
  }

  static void _doNothing() {}

  @override
  void mount(Element? parent, Object? newSlot) {
    if (container._element != null) {
      throw StateError(
        'Scope already attached to: ${container._element}. Cannot attach to $this.',
      );
    }
    if (container == ReadIt.instance) {
      assert(
        parent == null || Navigator.maybeOf(parent) == null,
        'The root `ProvideIt` widget must be above your app. ',
      );
    }

    container._element = this;
    super.mount(parent, newSlot);
  }

  int _frame = 0;
  bool _dirty = false;

  void markDirty() {
    if (_dirty) return;
    _dirty = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _frame++;
      container.finalizeTree();
      _dirty = false;
    });
  }

  @override
  void reassemble() {
    container.reassembleTree();
    super.reassemble();
  }

  @override
  void updated(covariant InheritedWidget oldWidget) {
    // assert(true, 'ProvideIt should be placed at the root of your app.');
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    if (aspect case (InheritedState state, InheritedAspect aspect)) {
      final dependencies =
          getDependencies(dependent) as _Dependencies? ??
          (frame: _frame, states: {});

      if (dependencies.frame != _frame) {
        // if new frame, we clear old dependencies
        dependencies.states
          ..forEach((state) => state.removeDependent(dependent)) // aspects
          ..clear();
      }

      // context.dependOnInheritedProvider
      state.addDependent(dependent, aspect);

      // we tie the dependencies to the current frame
      setDependencies(dependent, (
        frame: _frame,
        states: dependencies.states..add(state),
      ));
    }

    markDirty();
  }

  @override
  void removeDependent(Element dependent) {
    final dependencies = getDependencies(dependent) as _Dependencies?;
    dependencies?.states.forEach((s) => s.removeDependent(dependent));

    container.deactivateProviders(dependent);
    super.removeDependent(dependent);

    markDirty();
  }

  @override
  void unmount() {
    super.unmount();

    // we give a chance for binds to auto-dispose.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      assert(
        container._providers.isEmpty,
        '${container._providers.length} undisposed binds.',
      );
      container._element = null;
    });
  }

  /// Restart [ProvideIt] subtree and all its dependencies.
  void restart() {
    _restartKey = UniqueKey();
    markNeedsBuild();
  }

  Key? _restartKey;

  @override
  Widget build() {
    return Builder(
      key: _restartKey,
      builder: (context) {
        try {
          // we provide the providers to the tree.
          widget.provide?.call(context);
        } catch (e, s) {
          return widget.errorBuilder(context, e, s);
        }

        // we use [FutureRef] a.k.a `context.future` to wait for all async binds.
        final snapshot = context.useFuture(allReady);

        // if `allReady` is void (ready), we return child (super.build).
        return snapshot.maybeWhen(
          loading: () => widget.loadingBuilder(context),
          error: (e, s) => widget.errorBuilder(context, e, s),
          orElse: super.build,
        );
      },
    );
  }
}

typedef _Dependencies = ({int frame, Set<InheritedState> states});
