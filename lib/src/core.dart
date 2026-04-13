import 'dart:async';

import 'package:flutter/rendering.dart';

import '../provide_it.dart';
import 'framework.dart';

/// Extension methods that DO NOT depend on [BuildContext].
///
/// Use them freely.
extension ContextReaders on BuildContext {
  /// Reads a previously bound value by [T].
  T read<T>() {
    return scope.read<T>(context: this);
  }

  /// Reads a previously bound value by [T].
  ///
  /// Returns a [Future] if the value is not ready.
  FutureOr<T> readAsync<T>() {
    return scope.readAsync<T>(context: this);
  }

  /// The future when all [InheritedState.isReady] are completed.
  FutureOr<void> allReady() {
    return scope.allReady();
  }

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>() {
    return scope.isReady<T>(context: this);
  }
}

/// Extension methods that DO DEPEND on [BuildContext].
///
/// Use them directly in [Widget] `build` methods.
/// - [watch] and [select] can be used is any builder.
/// - [listen] and [listenSelected] cannot be used in unstable builders,
/// such as in `itemBuilder` of [ListView.builder], but can be used in a
/// stable context, such as in a [Builder] inside the `itemBuilder`.
///
extension ContextDependents on BuildContext {
  /// Watches a previously bound value by [T].
  ///
  /// Initializes the provider if not already.
  T watch<T>() {
    return dependOnInheritedProvider(aspect: _Watch());
  }

  /// Selects a previously bound value by [T].
  ///
  /// Initializes the provider if not already.
  S select<T, S>(S selector(T value)) {
    final value = dependOnInheritedProvider(aspect: _Select(selector));
    return selector(value);
  }

  /// Listens to a previously bound value by [T].
  ///
  /// Initializes the provider if not already.
  void listen<T>(void listener(T value)) {
    assert(this is! RenderSliverBoxChildManager, _unstableBuilder);
    dependOnInheritedProvider(aspect: _Listen(listener));
  }

  /// Listens to a previously bound value by [T], [selector].
  ///
  /// Initializes the provider if not already.
  void listenSelected<T, S>(
    S selector(T value),
    void listener(S prev, S next),
  ) {
    assert(this is! RenderSliverBoxChildManager, _unstableBuilder);
    dependOnInheritedProvider(aspect: _ListenSelected(selector, listener));
  }

  String get _unstableBuilder {
    // e.g. ListView.builder, SliverList.builder
    return 'Cannot listen on a unstable builder: wrap it in a Builder or refactor it into its own widget to obtain a stable build context.';
  }
}

class _Watch<T> extends InheritedAspect<T> {
  const _Watch();

  @override
  void didChange(Element dependent, T value) {
    dependent.markNeedsBuild();
  }
}

class _Listen<T> extends InheritedAspect<T> {
  const _Listen(this.listener);
  final void Function(T value) listener;

  @override
  void didChange(Element dependent, T value) {
    listener(value);
  }
}

class _Select<T, S> extends InheritedAspect<T> {
  _Select(this.selector);
  final S Function(T value) selector;
  late S _prev;

  @override
  void didDepend(Element dependent, T value) {
    _prev = selector(value);
  }

  @override
  void didChange(Element dependent, T value) {
    final next = selector(value);

    if (!ProvideIt.equals(_prev, next)) {
      dependent.markNeedsBuild();
      _prev = next;
    }
  }
}

class _ListenSelected<T, S> extends InheritedAspect<T> {
  _ListenSelected(this.selector, this.listener);
  final S Function(T value) selector;
  final void Function(S prev, S next) listener;
  late S _prev;

  @override
  void didDepend(Element dependent, T value) {
    _prev = selector(value);
  }

  @override
  void didChange(Element dependent, T value) {
    final next = selector(value);

    if (!ProvideIt.equals(_prev, next)) {
      listener(_prev, next);
      _prev = next;
    }
  }
}

extension ContextDependsOnInheritedProvider on BuildContext {
  /// Stablishes a dependency between this `context` and an [InheritedState] by [T].
  ///
  /// - When first depending on the provider, [InheritedAspect.didDepend] will be called. Then,
  /// for each [InheritedState.notifyDependents], [InheritedAspect.didChange] will be called.
  ///
  /// - When deactivated, [InheritedState.removeDependent] will be called for each
  /// provider dependency that this `context` depends on.
  T dependOnInheritedProvider<T>({required InheritedAspect<T> aspect}) {
    return scope.dependOnInheritedProvider<T>(this, aspect);
  }
}

extension ContextInheritProviders on BuildContext {
  /// Inherits all [InheritedProvider] from [ancestor] to `this`.
  ///
  /// This allows using [ContextReaders] and [ContextDependents] in simbling contexts,
  /// such as in dialogs, routes, overlays, etc.
  void inheritProviders(BuildContext ancestor) {
    assert(this != ancestor, 'Cannot inherit providers from itself.');
    scope.inheritProviders(this, ancestor);
  }
}

extension on BuildContext {
  @internal
  ScopeIt get scope => ScopeIt.of(this);
}
