part of '../framework.dart';

extension on ProvideItContainer {
  R _bind<T, R>(Element context, AnyProvider<T, R> provider) {
    final states = _providers[context] ??= HashMap();
    final index = _providerIndex[context] ??= 0;
    _providerIndex[context] = index + 1; // next provider index

    ProviderState<T, R> create() {
      final state = provider.createState()
        .._bind = (provider: provider, element: context, index: index);

      if (state case InheritedState state) {
        _registerProvider(state);
      }

      return states[index] = state..initState();
    }

    ProviderState<T, R> update(ProviderState<T, R> state) {
      assert(() {
        _reassembledProviders?.remove(state);
        return true;
      }());

      if (_inactiveProviders.remove(state)) {
        state.activate();

        if (state case InheritedState state) {
          _registerProvider(state);
        }
      }

      final oldProvider = state.provider; // keep before update

      return state
        .._bind = (provider: provider, element: context, index: index)
        ..didUpdateProvider(oldProvider);
    }

    ProviderState<T, R> replace(ProviderState old) {
      assert(() {
        final reassembled = _reassembledProviders?.remove(old) == true;
        return reassembled || old.provider.runtimeType == provider.runtimeType;
      }(), 'Provider state must be reassembled or key changed to replace.');

      _deactivateProvider(old);

      return create();
    }

    bool canUpdate(ProviderState<T, R> state) {
      return AnyProvider.canUpdate(state.provider, provider);
    }

    final state = switch (states[index]) {
      null => create(),
      ProviderState<T, R> it when canUpdate(it) => update(it),
      final state => replace(state), // reassembled or key changed
    };

    context.dependOnInheritedElement(_element!);

    return state.build(context);
  }

  void _registerProvider(InheritedState state) {
    _providerCache.update(
      state.type,
      (cache) => cache.add(state),
      ifAbsent: () => InheritedCache.single(state),
    );
  }

  void _unregisterProvider(InheritedState state) {
    if (_providerCache[state.type]?.remove(state) case final cache?) {
      _providerCache[state.type] = cache;
    } else {
      _providerCache.remove(state.type);
    }
  }

  void _deactivateProvider(ProviderState state) {
    if (!_inactiveProviders.add(state)) {
      return; // already deactivated
    }

    if (state is InheritedState) {
      _unregisterProvider(state);
    }

    state.deactivate();
  }

  @internal
  void deactivateProviders(BuildContext context) {
    _providers[context]?.forEach((_, state) => _deactivateProvider(state));
  }

  @internal
  void finalizeTree() {
    assert(() {
      // removed after reassemble, we deactivate/dispose it.
      _reassembledProviders?.forEach(_deactivateProvider);
      _reassembledProviders?.clear();
      return true;
    }());

    for (var state in _inactiveProviders) {
      final states = _providers[state.context]!;

      // we check as if may be replaced by a new state with the same index.
      if (states[state.index] == state) {
        states.remove(state.index);
        if (states.isEmpty) _providers.remove(state.context);
      }

      state
        ..dispose()
        .._bind = null; // unbind after dispose
    }

    _inactiveProviders.clear();
    _providerIndex.clear();
  }

  @internal
  void reassembleTree() {
    assert(() {
      _reassembledProviders ??= HashSet();
      _providers.forEach((_, states) {
        states.forEach((_, state) {
          // reassembled providers should update, otherwise we deactivate it.
          _reassembledProviders?.add(state..reassemble());
        });
      });
      return true;
    }());
  }
}
