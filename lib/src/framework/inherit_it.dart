part of '../framework.dart';

typedef TypeOf<T> = T;

/// Engine for [InheritedProvider] that manages provider inheritance and lookup.
mixin InheritIt on InheritedScope {
  final _byType = HashMap<Type, InheritedCache>.identity();
  final _bySymbol = HashMap<String, InheritedCache>();

  final _types = HashMap<String, Type>();

  void _inherit<T>(InheritedBind<T> bind) {
    if (T != dynamic && T != TypeOf<Object?>) _types[bind.type] ??= TypeOf<T?>;

    final type = _types[bind.type] ?? bind.type;
    final map = type is Type ? _byType : _bySymbol;
    map[type] = map[type]?.add(bind) ?? InheritedCache.single(bind);
  }

  void _disinherit<T>(InheritedBind<T> bind) {
    final type = _types[bind.type] ?? bind.type;
    final map = type is Type ? _byType : _bySymbol;

    if (map[type]!.remove(bind) case final cache?) {
      map[type] = cache;
    } else {
      map.remove(_types.remove(bind.type) ?? bind.type)!;
    }
  }

  @protected
  InheritedBind? getInheritedBind<T>({String? type, BuildContext? context}) {
    final Type t = TypeOf<T?>;
    var cache = _byType[t];

    if (cache == null) {
      if (type != null) {
        cache = _byType[_types[type]] ?? _bySymbol[type];
      } else if (_bySymbol.remove(type ??= T.type) case final match?) {
        cache = _byType[_types[type] = t] = match;
      }
    }
    if (cache case InheritedBind? bind) return bind;

    // we disambiguate by inheritance, like InheritedWidget.
    if (context != null) {
      if (cache?[context] case final bind? when bind.wasDiscovered) {
        return bind;
      }

      final ref = InheritedRef(context);
      if (ref.read<T>() case final bind?) return bind;

      bool visit(BuildContext element) {
        if (cache?[element] case final bind?) {
          ref.write<T>(bind);
          return false; // closest found, stop visiting
        }

        // we jump to the next binding context
        if (InheritedRef(element).ancestor case final ancestor?) {
          if (visit(ancestor)) ancestor.visitAncestorElements(visit);
          return false; // redirected
        }
        return true; // keep visiting
      }

      if (visit(context)) context.visitAncestorElements(visit);

      if (ref.read<T>() case final bind?) return bind;
    }

    throw ProviderMultipleFoundException('Multiple $type found');
  }

  /// Makes [context] inherit providers from another [ancestor] context. Essentially
  /// making it an "ancestor" for provider lookup purposes.
  ///
  /// This allows [getInheritedBind] to traverse the provider tree when looking
  /// for providers in sibling contexts, essentially inheriting providers from [ancestor].
  @protected
  void inheritProviders(BuildContext context, BuildContext ancestor) {
    InheritedRef(context).ancestor = ancestor;
  }
}

extension on Bind {
  /// Whether this bind was discovered in this frame, and its ready to be read.
  /// Ensures we won't read a bind that was bound later in the same build node.
  /// O(1) in most cases.
  bool get wasDiscovered {
    final binds = scope.currentNode?.binds;
    if (!identical(binds, list)) return false; // reading before binds

    // when null (end-of-list), all binds were discovered, safe to read
    var bind = binds?.current?.previous;
    if (bind == null) return true; // reading after binds

    // when not, we check if it was previously discovered
    for (; bind != null; bind = bind.previous) {
      if (identical(bind, this)) return true; // reading between binds
    }

    return false;
  }
}

/// An optimized union that can hold either a single state or many,
/// as most providers usually have only one state per type.
@internal
extension type InheritedCache._(Object _) {
  factory InheritedCache.single(InheritedBind value) {
    return InheritedCache._(value);
  }

  InheritedCache add(InheritedBind state) {
    switch (this) {
      case InheritedBind single:
        assert(
          single.dependent != state.dependent,
          'Duplicate ${state.debugLabel}.',
        );
        final map = HashMap<BuildContext, InheritedBind>();
        map[single.dependent] = single;
        map[state.dependent] = state;
        return InheritedCache._(map);
      case Map<BuildContext, InheritedBind> map:
        assert(
          !map.containsKey(state.dependent),
          'Duplicate ${state.debugLabel}.',
        );
        map[state.dependent] = state;
        return this;
      default:
        throw StateError('Invalid InheritedCache: $this');
    }
  }

  InheritedCache? remove(InheritedBind state) {
    switch (this) {
      case InheritedBind prev when prev == state:
        return null;
      case Map map when map.remove(state.dependent) != null && map.length == 1:
        return InheritedCache.single(map.values.first);
      default:
        return this;
    }
  }

  void forEach(void action(InheritedBind state)) {
    switch (this) {
      case InheritedBind state:
        action(state);
      case Map<BuildContext, InheritedBind> map:
        map.forEach((_, state) => action(state));
      default:
        throw StateError('Invalid InheritedCache: $this');
    }
  }

  // disambiguates providers by context.
  InheritedBind? operator [](BuildContext context) => switch (this) {
    Map<BuildContext, InheritedBind> map => map[context],
    _ => null,
  };
}

/// Weak reference to [InheritedBind] that optimizes lookups when
/// disambiguating providers by [Type] & [BuildContext] scope.
@internal
extension type InheritedRef(BuildContext context) {
  static final _ref = Expando<_Ref>('InheritedRef');

  BuildContext? get ancestor => _ref[context]?.ancestor;

  set ancestor(BuildContext? ancestor) {
    final ref = _ref[context];
    assert(
      ref?.ancestor == null || ref!.ancestor == ancestor,
      'Context $context is already inheriting providers from ${ref.ancestor}.',
    );
    _ref[context] = (binds: ref?.binds, ancestor: ancestor);
  }

  InheritedBind? read<T>() => _ref[context]?.binds?[TypeOf<T>];

  void write<T>(InheritedBind state) {
    final ref = _ref[context];
    final t = TypeOf<T>;

    switch (ref?.binds) {
      case null:
        _ref[context] = (
          binds: HashMap()..[t] = state,
          ancestor: ref?.ancestor,
        );
      case final states:
        states[t] = state;
    }
  }
}

typedef _Ref = ({Map<Type, InheritedBind>? binds, BuildContext? ancestor});

class ProviderNotFoundException implements Exception {
  ProviderNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'ProviderNotFoundException: $message';
}

class ProviderMultipleFoundException implements Exception {
  ProviderMultipleFoundException(this.message);
  final String message;

  @override
  String toString() => 'ProviderMultipleFoundException: $message';
}
