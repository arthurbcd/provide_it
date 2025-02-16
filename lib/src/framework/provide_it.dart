part of 'framework.dart';

typedef NamedLocator = dynamic Function(NamedParam param);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.watchers = const DefaultWatchers([]),
    this.namedLocator,
    this.allowedDuplicates = const [],
    required super.child,
  });

  /// List of [Watcher]s to use for the [ContextReaders] framework.
  ///
  /// The [DefaultWatchers] list comes with:
  /// - [ListenableWatcher]
  final List<Watcher> watchers;

  /// List of types allowed to have duplicate values on read.
  ///
  /// Types not in this list will be treated as strict and cannot have duplicate values,
  /// unless a key exists to differentiate them.
  ///
  /// - Set to `[]` to strictly enforce no duplicates.
  /// - Set to `null` to allow duplicates for all types.
  ///
  /// Using binds directly does not enforce this rule, as you are not
  /// reading it from the context.
  ///
  /// ```dart
  /// // when using locally, duplicates are always allowed.
  /// final (name, setName) = context.value('');
  /// final (title, setTitle) = context.value('');
  /// final (email, setEmail) = context.value('', key: 'email');
  ///
  /// // unless `allowedDuplicates` contains `String`, then:
  /// final title = context.read<String>(); // not allowed
  /// final email = context.read<String>(key: 'email'); // allowed
  /// ```
  final List<Type>? allowedDuplicates;

  /// Injects a [NamedParam] during creation.
  /// - If not found, [ContextReaders.read] uses [Param.type].
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

  /// Logs the current state of the [RefState] tree.
  static void log() => _instance.debugTree();

  @override
  bool updateShouldNotify(covariant ProvideIt oldWidget) =>
      oldWidget.watchers != watchers || oldWidget.namedLocator != namedLocator;

  @override
  InheritedElement createElement() => ProvideItElement(this);
}
