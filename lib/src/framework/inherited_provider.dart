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
abstract class InheritedProvider<T> extends BindProvider<void> {
  const InheritedProvider({super.key});

  @protected
  InheritedState<T, InheritedProvider<T>> createState();

  @override
  Bind<void> createBind() => InheritedBind(this);
}

class InheritedBind<T> extends Bind<void> {
  InheritedBind(InheritedProvider<T> super.provider)
    : _state = provider.createState() {
    state._bind = this;
  }
  InheritedState<T, InheritedProvider<T>>? _state;
  InheritedState<T, InheritedProvider<T>> get state => _state!;

  @override
  String get debugLabel => state.debugLabel;

  @override
  void bind() {
    owner._registerType(state);
    state.initState();
    super.bind();
  }

  @override
  void update(InheritedProvider<T> newProvider) {
    final oldProvider = provider as InheritedProvider<T>;
    super.update(newProvider);
    state.updated(oldProvider);
  }

  @override
  void activate() {
    owner._registerType(state);
    super.activate();
  }

  @override
  void deactivate() {
    _unwatch();
    owner._unregisterType(state);
    super.deactivate();
  }

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void unbind() {
    state.dispose();
    _state = null;
    super.unbind();
  }

  bool watched = false;
  VoidCallback? _cancelWatcher;

  void _watch() {
    _cancelWatcher = owner._element!.tryWatch<T>(state);
    watched = true;
  }

  void _unwatch() {
    _cancelWatcher?.call();
    watched = false;
  }

  @override
  void build() {
    if (!watched && state.isReady() == null) {
      _watch();
    }
  }
}

/// An abstract class that represents the state of a [BindProvider].
///
/// This class is intended to be extended by other classes that manage the state
/// of a [BindProvider] of type [T] and a reference type [R] that extends [Ref<T>].
///
/// The [InheritedState] class provides a base for managing the lifecycle and state
/// transitions of a reference, allowing for more complex state management
/// patterns to be implemented.
///
/// This class is designed with the [State] class of a [StatefulWidget] in mind,
/// and like it, will be used to persist the state of its reference [BindProvider].
///
/// Type Parameters:
/// - [T]: The type of the value used by [read], [watch], [select], [listen]
/// - [R]: The [BindProvider] type that this state is associated with.
///
/// See also:
/// - [ContextProvide]
/// - [ContextProvideValue]
///
abstract class InheritedState<T, R extends InheritedProvider<T>> {
  InheritedBind<T>? _bind;

  @visibleForTesting
  String get debugLabel;

  @visibleForTesting
  final String type = switch (T.toString()) {
    final type when null is! T => type,
    final type => type.substring(0, type.length - 1),
  };

  @visibleForTesting
  Set<Element> get dependents => _dependents.keys.toSet();

  final _dependents = HashMap<Element, List<InheritedAspect>>();

  @protected
  R get provider => _bind!.provider as R;

  @protected
  BuildContext get context => _bind!.element;

  @mustCallSuper
  void initState() {}

  @mustCallSuper
  void updated(covariant R oldProvider) {}

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

  @mustCallSuper
  void reassemble() {
    _dependents.clear();
  }

  @mustCallSuper
  void dispose() {}

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
