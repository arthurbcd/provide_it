part of '../framework.dart';

mixin WatchIt on InheritIt {
  @protected
  T dependOnInheritedProvider<T>(Element dependent, InheritedAspect<T> aspect) {
    final state = getInheritedState<T>(context: dependent);
    if (state == null) {
      if (null is T) return null as T;
      throw MissingProviderException('InheritedProvider<$T> not found.');
    }

    dependent.dependOnInheritedElement(this, aspect: (state, aspect));

    if (state.read() case T value) {
      aspect.didDepend(dependent, value);
      return value;
    }

    throw LoadingProvideException('${state.debugLabel} is loading.');
  }

  @override
  Dependencies? getDependencies(Element dependent) {
    return super.getDependencies(dependent) as Dependencies?;
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    if (aspect case (InheritedState state, InheritedAspect aspect)) {
      final dependencies =
          getDependencies(dependent) ?? (frame: _frame, states: {});

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
    final dependencies = getDependencies(dependent);
    dependencies?.states.forEach((s) => s.removeDependent(dependent));

    super.removeDependent(dependent);
  }
}

@internal
typedef Dependencies = ({int frame, Set<InheritedState> states});
