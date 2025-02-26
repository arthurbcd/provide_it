part of '../framework.dart';

class ProvideItElement extends InheritedElement {
  late final scope = (widget.scope ?? ReadIt.instance) as ProvideItScope;

  ProvideItElement(ProvideIt super.widget) {
    // attach scope to the widget tree.
    scope._element = this;
    scope.watchers.addAll(widget.additionalWatchers);

    // attach the default locator to the scope.
    Injector.defaultLocator = (param) {
      Object? value;
      if (param is NamedParam) value = widget.namedLocator?.call(param);
      return value ?? scope.readAsync(type: param.type);
    };
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  bool _reassembled = false;

  @override
  void reassemble() {
    for (final state in scope.states) {
      state.reassemble();
    }
    super.reassemble();
    _reassembled = true;
  }

  @override
  void removeDependent(Element dependent) {
    scope._tree[dependent]?.values.forEach((state) => state.deactivate());

    void dispose() {
      scope._tree.remove(dependent)?.values.forEach((state) => state.dispose());
      scope._treeIndex.remove(dependent);

      scope._dependentIndex.remove(dependent);
      scope._dependents
          .remove(dependent)
          ?.forEach((s) => s.removeDependent(dependent));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been removed from the tree.
      // if it's still mounted, we reactivate.
      dependent.mounted
          ? scope._tree[dependent]?.values.forEach((state) => state.activate())
          : dispose();
    });

    super.removeDependent(dependent);
  }

  @override
  Widget build() {
    _reassembled = false;

    // we bind the provided states
    widget.provide?.call(this);

    // if `allReady` is void, we immediately return `super.build`.
    final snapshot = future(allReady);

    return snapshot.maybeWhen(
      loading: () => widget.loadingBuilder(this),
      error: (e, s) => widget.errorBuilder(this, e, s),
      orElse: super.build,
    );
  }
}

extension on BuildContext {
  /// Stablishes a dependency between this `context` and [RefState]/[ProvideItElement].
  ///
  /// [ProvideItElement.removeDependent] will be called when this `context` is unmounted.
  /// Then, any [RefState] this `context` depends on will call [RefState.removeDependent].
  void dependOnRefState(RefState state, String method, [String? instead]) {
    assert(
      this is Element && debugDoingBuild,
      '$method() should be called within the build(). ${instead ?? ''}',
    );
    final ProvideItScope scope = state._scope!;

    // we depend so we can get notified by [removeDependent].
    dependOnInheritedElement(scope._element!);

    // we register the dependent so we can remove it when unmounted.
    final dependents = scope._dependents[this] ??= {};
    dependents.add(state);
  }
}

extension on ReadItMixin {
  void _assertState<T>(_State? state, String method, Object? key) {
    assert(
      state != null,
      'Failed to $method(). Ref<$T> not found, key: $key.',
    );
  }
}
