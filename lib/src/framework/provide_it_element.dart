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
  late final scope = switch (widget.scope) {
    null => !readIt.mounted ? ReadIt.instance : ReadIt.asNewInstance(),
    final scope => scope,
  } as ProvideItScope;

  bool _reassembled = false;
  bool _firstFrame = true;

  bool get isBuilding {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks ||
        _firstFrame && phase == SchedulerPhase.idle;
  }

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
    super.mount(parent, newSlot);
    scope._element = this;
    _applyOverrides();

    SchedulerBinding.instance.addPostFrameCallback((_) => _firstFrame = false);
  }

  void _applyOverrides() {
    overrides.clear();

    OverrideRef._element = this;
    widget.override?.call(OverrideContext(this));
    OverrideRef._element = null;
  }

  @override
  void reassemble() {
    _applyOverrides();

    for (final bind in scope.binds) {
      bind.reassemble();
    }
    super.reassemble();

    _reassembled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _reassembled = false);
  }

  @override
  void removeDependent(Element dependent) {
    // we sync as [Element.deactivate] was called.
    final binds = scope._binds[dependent]
      ?..forEach((_, bind) => bind.deactivate());

    // binds must immediately stop notifying this dependent.
    final observers = scope._observers.remove(dependent)
      ?..forEach((bind) => bind.removeDependent(dependent));

    super.removeDependent(dependent);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been displaced from the tree.
      // if still mounted, we activate it.
      if (dependent.mounted) {
        binds?.forEach((_, bind) => bind.activate());

        if (observers == null || observers.isEmpty) return;

        // observers should be re-activated on next frame.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final newObservers = scope._observers[dependent];

          // we ensure the observers are reactivated, this should rarely happen
          if (dependent.mounted && !setEquals(observers, newObservers)) {
            dependent.markNeedsBuild();

            if (kDebugMode) {
              print(
                'ProvideIt: Warning - Re-activating removed observers of ${dependent.widget}.',
              );
            }
          }
        });
      } else {
        scope._binds.remove(dependent)?.forEach((_, bind) => bind.dispose());
        scope._inheritedScopes.remove(dependent);
      }
    });
  }

  @override
  void unmount() {
    super.unmount();

    // we give a chance for binds to auto-dispose.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      assert(scope._binds.isEmpty, '${scope._binds.length} undisposed binds.');
      scope._element = null;
    });
  }

  /// Restart [ProvideIt] subtree and all its bind dependencies.
  void restart() {
    _restartKey = UniqueKey();
    markNeedsBuild();
  }

  // final refOverrides = <Ref, Ref>{};
  final overrides = <String, OverrideRef>{};

  Key? _restartKey;

  @override
  Widget build() {
    return Builder(
      key: _restartKey,
      builder: (context) {
        try {
          // we bind the overrides/providers to the tree.
          widget.provide?.call(context);
        } catch (e, s) {
          return widget.errorBuilder(context, e, s);
        }

        // we use [FutureRef] a.k.a `context.future` to wait for all async binds.
        final snapshot = context.future(allReady);

        // if `allReady` is void (ready), we immediately return `super.build`.
        return snapshot.maybeWhen(
          loading: () => widget.loadingBuilder(context),
          error: (e, s) => widget.errorBuilder(context, e, s),
          orElse: super.build,
        );
      },
    );
  }
}

class OverrideRef<T> extends ProvideRef<T> {
  OverrideRef(super.value) : super.value();

  static ProvideItElement? _element;
  static ProvideItElement get element {
    assert(_element != null, 'Cannot override outside of ProvideIt.override.');
    return _element!;
  }
}

extension on BuildContext {
  /// Stablishes a dependency between this `context` and [bind].
  ///
  /// When disabled, [Bind.removeDependent] will be called for each
  /// bind dependency that this `context` depends on.
  void dependOnBind(Bind bind, String method, [String? instead]) {
    final ProvideItScope scope = bind._scope;
    final isActivating = bind._deactivated && !bind._disposed;
    assert(
      scope._element!.isBuilding || isActivating,
      '$method() should be called within the build(). ${instead ?? ''}',
    );

    // we depend so we can get notified by [Element.removeDependent].
    dependOnInheritedElement(scope._element!);

    // we register it to notify the depending binds [Bind.removeDependent].
    final dependencies = scope._observers[this as Element] ??= {};
    dependencies.add(bind);
  }
}
