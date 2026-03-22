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
  const InheritedProvider({super.key, this.lazy});

  /// Whether to create the value only when it's first read.
  /// When false, value is immediately created on provide.
  final bool? lazy;

  @protected
  InheritedState<T, InheritedProvider<T>> createState();

  @override
  Bind<void> createBind() => InheritedBind(this);
}

final class InheritedBind<T> extends Bind<void> {
  InheritedBind(InheritedProvider<T> super.provider)
    : _state = provider.createState() {
    state._bind = this;
  }
  InheritedState<T, InheritedProvider<T>>? _state;
  InheritedState<T, InheritedProvider<T>> get state => _state!;

  @override
  InheritedProvider<T> get provider => super.provider as InheritedProvider<T>;

  @override
  String get debugLabel => state.debugLabel;

  String get type => state.type;

  Symbol get symbol => Symbol(type);

  @mustCallSuper
  T depend(Element dependent, InheritedAspect<T?> aspect) {
    state.addDependent(dependent, aspect);

    final value = read();
    if (value is Future<T>) {
      throw ProviderNotReadyException('$debugLabel is not ready.');
    }
    if (_value != value && value != null) {
      if (_value == null || _watcher != null) {
        _watcher?.cancel(_value!, state.notifyDependents);
        _watcher ??= scope.widget.resolveWatcher(value);
        _watcher?.listen(value, state.notifyDependents);
      }
      _value = value;
    }
    aspect.didDepend(dependent, value);
    return value;
  }

  // we can't type the covariant as T
  Watcher? _watcher;
  T? _value;

  @mustCallSuper
  void removeDependent(Element dependent) {
    state.removeDependent(dependent);
  }

  @override
  void bind() {
    super.bind();
    scope._inherit(this);
    state.initState();
    if (provider.lazy == false) {
      state.read();
    }
  }

  @override
  void update(InheritedProvider<T> newProvider) {
    final oldProvider = provider;
    super.update(newProvider);
    state.updated(oldProvider);
    if (state.selfDependent) state.removeDependent(dependent);
  }

  @override
  void activate() {
    scope._inherit(this);
    _watcher?.listen(_value!, state.notifyDependents);
    super.activate();
  }

  @override
  void deactivate() {
    scope._disinherit(this);
    _watcher?.cancel(_value!, state.notifyDependents);
    super.deactivate();
  }

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void unbind() {
    _watcher?.dispose(_value!);
    state.dispose();
    super.unbind();
    _watcher = _value = _state = state._bind = null;
  }

  FutureOr<void> isReady() => state.isReady();

  FutureOr<T> read() => state.read();

  @override
  void build() {}
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
  final _dependents = HashMap<Element, List<InheritedAspect<T?>>>();

  @visibleForTesting
  String get debugLabel;

  @visibleForTesting
  final String type = switch (T.toString()) {
    final t when null is! T => t,
    final t => t.substring(0, t.length - 1),
  };

  @visibleForTesting
  Set<Element> get dependents => _dependents.keys.toSet();

  @visibleForTesting
  bool get selfDependent => _dependents.containsKey(_bind!.dependent);

  @protected
  ReadIt get scope => _bind!.scope;

  @protected
  BuildContext get context => _bind!.dependent;

  @protected
  R get provider => _bind!.provider as R;

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
    // TODO: probably breaks readAsync
    final value = read() as T;

    _dependents.forEach((Element element, List<InheritedAspect<T?>> aspects) {
      for (var i = 0; i < aspects.length; i++) {
        aspects[i].didChange(element, value);
      }
    });
  }

  @protected
  @mustCallSuper
  void addDependent(Element dependent, InheritedAspect<T?> aspect) {
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
  FutureOr<void> isReady();

  @protected
  FutureOr<T> read();
}

abstract class InheritedAspect<T> {
  const InheritedAspect();

  @protected
  void didDepend(Element dependent, T value) {}

  @protected
  void didChange(Element dependent, T value);
}

class ProviderNotReadyException implements Exception {
  ProviderNotReadyException(this.message);
  final String message;

  @override
  String toString() => 'LoadingProvideException: $message';
}
