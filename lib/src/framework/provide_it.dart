part of 'framework.dart';

typedef NamedLocator = dynamic Function(NamedParam param);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.watchers = const DefaultWatchers([]),
    this.namedLocator,
    required super.child,
  });

  /// List of [Watcher]s to use for the [ContextBinds] framework.
  ///
  /// The [DefaultWatchers] list comes with:
  /// - [ListenableWatcher]
  final List<Watcher> watchers;

  /// Injects a [NamedParam] during creation.
  /// - If not found, [ContextBinds.read] uses [Param.type].
  /// - Only for named parameters, not positional.
  ///
  /// Example with router path parameters:
  ///
  /// ```dart
  /// ProvideIt.root(
  ///   namedLocator: (param) => myRouter.pathParameters[param.name],
  ///   child: MyApp(),
  /// );
  /// ```
  ///
  /// Auto-injects `pathParameters` to `MyClass.new`:
  ///
  /// ```dart
  /// class MyClass {
  ///   MyClass({required this.myId});
  ///   final String myId; // auto-injected if pathParameters['myId'] exists.
  /// }
  /// ```
  final NamedLocator? namedLocator;

  /// Logs the current state of the [ContextRefs] tree.
  static void log() => _instance.debugTree();

  @override
  bool updateShouldNotify(covariant ProvideIt oldWidget) =>
      oldWidget.watchers != watchers || oldWidget.namedLocator != namedLocator;

  @override
  InheritedElement createElement() => ProvideItElement(this);
}
