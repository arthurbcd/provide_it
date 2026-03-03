part of '../framework.dart';

/// [InheritedProvider] is used to provide values to the widget tree.
/// They are similar to [InheritedWidget] but with more features.
/// - They are not limited to the current widget tree.
/// - As long as the [InheritedProvider] is bound to a [BuildContext], it can be used anywhere.
/// - They can be used to manage the lifecycle of values with [InheritedState].
/// - They automatically dispose when the [BuildContext] is unmounted.
/// - You can `read`, `watch`, `listen`, and `select` provider values.
///
/// You must set [ProvideIt] in the root of your app.
///
/// See [InheritedState] for more details.
abstract class InheritedProvider<T> extends AnyProvider<T, void> {
  const InheritedProvider({super.key});

  @override
  InheritedState<T, InheritedProvider<T>> createState();
}

/// An abstract class that represents the state of a [AnyProvider].
///
/// This class is intended to be extended by other classes that manage the state
/// of a [AnyProvider] of type [T] and a reference type [R] that extends [Ref<T>].
///
/// The [InheritedState] class provides a base for managing the lifecycle and state
/// transitions of a reference, allowing for more complex state management
/// patterns to be implemented.
///
/// This class is designed with the [State] class of a [StatefulWidget] in mind,
/// and like it, will be used to persist the state of its reference [AnyProvider].
///
/// Type Parameters:
/// - [T]: The type of the value used by [read], [watch], [select], [listen]
/// - [R]: The [AnyProvider] type that this state is associated with.
///
/// See also:
/// - [ContextProvide]
/// - [ContextProvideValue]
///
abstract class InheritedState<T, R extends InheritedProvider<T>>
    extends ProviderState<T, void> {
  @visibleForTesting
  final String type = switch (T.toString()) {
    final type when null is! T => type,
    final type => type.substring(0, type.length - 1),
  };

  @visibleForTesting
  Set<Element> get dependents => _dependents.keys.toSet();

  final _dependents = HashMap<Element, List<InheritedAspect>>();

  @override
  R get provider => super.provider as R;

  @override
  @mustCallSuper
  void didUpdateProvider(covariant R oldProvider) {}

  /// Notifies all dependents [InheritedAspect] of this [InheritedState].
  ///
  /// An aspect can be a [watch], [listen], [select], [listenSelected] or any custom aspect
  /// that invokes [ContextDependsOnInheritedProvider].
  ///
  /// Unlike [State.setState], this method triggers a rebuild only for widgets depending on this provider,
  /// not the provider itself.
  ///
  @protected
  @mustCallSuper
  void notifyDependents() {
    if (dependents.isEmpty) {
      return;
    }
    final value = read();
    assert(value is T, 'Cannot notify dependents when not ready.');

    _dependents.forEach((Element element, List<InheritedAspect> aspects) {
      for (var i = 0; i < aspects.length; i++) {
        aspects[i].didChange(element, value);
      }
    });
  }

  @protected
  @mustCallSuper
  void addDependent(Element dependent, InheritedAspect aspect) {
    (_dependents[dependent] ??= []).add(aspect);
  }

  @protected
  @mustCallSuper
  void removeDependent(Element dependent) {
    _dependents.remove(dependent);
  }

  @override
  void reassemble() {
    _dependents.clear();
    super.reassemble();
  }

  @override
  @mustCallSuper
  void build(BuildContext context) {}

  @protected
  FutureOr<void> isReady() => null;

  @protected
  FutureOr<T> read();
}

abstract class InheritedAspect<T> {
  const InheritedAspect();

  @protected
  void didDepend(Element dependent, T value) {
    // Handles the initial value when first depending on the provider.
  }

  @protected
  void didChange(Element dependent, T value);
}
