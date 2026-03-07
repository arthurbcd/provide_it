part of '../framework.dart';

mixin WatchIt on InheritIt {
  @override
  void changeNode(Node? prev, Node next) {
    super.changeNode(prev, next);
    next.dirty = true;
  }

  @protected
  T dependOnInheritedProvider<T>(Element dependent, InheritedAspect<T> aspect) {
    final state = getInheritedState<T>(context: dependent);
    if (state == null) {
      if (null is T) return null as T;
      throw MissingProviderException('InheritedProvider<$T> not found.');
    }

    final node = dependent.dependOnScope(this);
    if (node.dirty) {
      node.clearDependencies();
    }
    final states = node.states ??= HashSet();

    state.addDependent(dependent, aspect);
    states.add(state);

    if (state.read() case T value) {
      aspect.didDepend(dependent, value);
      return value;
    }

    throw LoadingProvideException('${state.debugLabel} is loading.');
  }

  @override
  void deactivateNode(Node node) {
    node.clearDependencies();
    super.deactivateNode(node);
  }
}

@internal
typedef Dependency = ({int frame, Set<InheritedState> states});

mixin Dependencies on Bindings {
  Set<InheritedState>? states;
  bool dirty = false;

  void clearDependencies() {
    states?.forEach((state) => state.removeDependent(dependent));
    states?.clear();
    dirty = false;
  }
}
