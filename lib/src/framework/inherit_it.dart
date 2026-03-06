part of '../framework.dart';

/// Engine for [InheritedProvider] that manages provider inheritance and lookup.
mixin InheritIt on BindIt {
  // inherited state cache by type
  final _inheritedCache = HashMap<String, InheritedCache>();

  void _inheritState(InheritedState state) {
    _inheritedCache.update(
      state.type,
      (cache) => cache.add(state),
      ifAbsent: () => InheritedCache.single(state),
    );
  }

  void _disinheritState(InheritedState state) {
    if (_inheritedCache[state.type]?.remove(state) case final cache?) {
      _inheritedCache[state.type] = cache;
    } else {
      _inheritedCache.remove(state.type);
    }
  }

  @protected
  InheritedState? getInheritedState<T>({String? type, BuildContext? context}) {
    // we return it right away when null or single
    final InheritedCache? cache = _inheritedCache[type ??= T.type];
    if (cache case InheritedState? state) return state;

    // we disambiguate by inheritance, like InheritedWidget.
    if (context is Element) {
      final ref = InheritedRef(context);
      if (ref.read<T>() case final state?) {
        return state;
      }

      bool visit(Element element) {
        if (cache[element] case final state?) {
          ref.write<T>(state);
          return false; // closest found, stop visiting
        }

        // we jump to the next binding context
        if (InheritedRef(element).ancestor case Element ancestor) {
          if (visit(ancestor)) ancestor.visitAncestorElements(visit);
          return false; // redirected
        }
        return true; // keep visiting
      }

      if (visit(context)) context.visitAncestorElements(visit);
      if (ref.read<T>() case final state?) return state;
    }

    throw StateError('Multiple provide<$type> found.');
  }

  /// Makes [context] inherit providers from another [ancestor] context. Essentially
  /// making it an "ancestor" for provider lookup purposes.
  ///
  /// This allows [getInheritedState] to traverse the provider tree when looking
  /// for providers in sibling contexts, essentially inheriting providers from [ancestor].
  @protected
  void inheritProviders(BuildContext context, BuildContext ancestor) {
    assert(context != ancestor, 'Cannot inherit providers from itself.');
    InheritedRef(context).ancestor = ancestor;
  }
}

/// An optimized cache that can hold either a single state or many,
/// as most providers usually have only one state per type.
@internal
extension type InheritedCache._(Object _) {
  factory InheritedCache.single(InheritedState value) {
    return InheritedCache._(value);
  }

  // TODO: consider allowing overriding providers in the same context by type,
  // which would simplify this logic. removing asserts.
  InheritedCache add(InheritedState state) {
    switch (this) {
      case InheritedState single:
        assert(
          single.context != state.context,
          'Duplicate ${state.debugLabel}.',
        );
        final map = HashMap<BuildContext, InheritedState>();
        map[single.context] = single;
        map[state.context] = state;
        return InheritedCache._(map);
      case Map<BuildContext, InheritedState> map:
        assert(
          !map.containsKey(state.context),
          'Duplicate ${state.debugLabel}.',
        );
        map[state.context] = state;
        return this;
      default:
        throw StateError('Invalid InheritedCache: $this');
    }
  }

  InheritedCache? remove(InheritedState state) {
    switch (this) {
      case InheritedState prev when prev == state:
        return null;
      case Map map when map.remove(state.context) != null && map.length == 1:
        return InheritedCache.single(map.values.first);
      default:
        return this;
    }
  }

  void forEach(void action(InheritedState state)) {
    switch (this) {
      case InheritedState state:
        action(state);
      case Map<BuildContext, InheritedState> map:
        map.forEach((_, state) => action(state));
      default:
        throw StateError('Invalid InheritedCache: $this');
    }
  }

  // disambiguates providers by context.
  InheritedState? operator [](BuildContext context) => switch (this) {
    Map<BuildContext, InheritedState> map => map[context],
    _ => null,
  };
}

/// Weak reference to [InheritedState] that optimizes lookups when
/// disambiguating providers by [Type] & [BuildContext] scope.
@internal
extension type InheritedRef(BuildContext context) {
  static final _ref = Expando<_Ref>('InheritedRef');

  BuildContext? get ancestor => _ref[context]?.ancestor;

  set ancestor(BuildContext? ancestor) {
    _ref[context] = (states: _ref[context]?.states, ancestor: ancestor);
  }

  InheritedState? read<T>() => _ref[context]?.states?[T];

  void write<T>(InheritedState state) {
    final ref = _ref[context];

    switch (ref?.states) {
      case null:
        _ref[context] = (
          states: HashMap()..[T] = state,
          ancestor: ref?.ancestor,
        );
      case final states:
        states[T] = state;
    }
  }
}

typedef _Ref = ({Map<Type, InheritedState>? states, BuildContext? ancestor});

extension ContextOf on ScopeIt {
  /// Automatically calls [read] or [watch] based on the [listen] parameter.
  ///
  /// When `listen` is null (default), it automatically decides based on whether
  /// the widget is currently in build/layout/paint pipeline, but you can enforce
  /// specific behavior by explicitly setting `listen` to true or false.
  ///
  T of<T>(BuildContext context, {bool? listen}) {
    if (listen ?? isBuilding) {
      return context.watch<T>();
    } else {
      return read<T>(context: context);
    }
  }
}

class MissingProviderException implements Exception {
  MissingProviderException(this.message);
  final String message;

  @override
  String toString() => 'MissingProvideException: $message';
}
