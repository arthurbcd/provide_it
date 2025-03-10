# Changelog

## 0.12.0

- Simplified `ProvideIt` api.
- Removed `context.write(T)`.

## 0.11.0

- Improved `Watcher` api & docs.
- Improved hot-reload experience when changing binds.
- Updated `README.md`.

## 0.10.0

- Added `context.write(T)`.
- Added support to use `Ref` as top-level member.
- Improved `RefState`, now overrides `T? value`.
- Improved `RefState.dispose(T)` to not be called when a lazy was not yet used.
- Improved errors/asserts.

## 0.9.0

- Improved `AsyncRefState.load` to unsubscribe old futures/streams.
- Removed the need for `BuildContext` in `RefState.bind`. Simply use `Ref.context`, instead.
- Now it's possible to read using T?, if not found, returns null instead of throwing.
- Exposed `RefState.dependents` api.
- Exposed `BuildContext.findRefStateOfType` api.
- Improved asserts.
- Added tests.

## 0.8.2

- Improved [RefState.removeDependent]. Now O(1).
- Added internal [BuildContext.dependOnRefState].

## 0.8.1

- Removed unnecessary `read` dependency on `ProvideIt`.
- Improved context dependency asserts.

## 0.8.0

- Changed [Injector.parameters] to use [Symbol] instead of [String].
- Improved [ReadIt] type resolution.
- Improved [Injector.toString] 
- Improved [Param.toString].
- Improved async injections.
- Updated example.
- Updated `README.md`.
- Bump min constraints to Dart 3.3.0 / Flutter 3.19.0.

## 0.7.0

- Improved lookup: O(1) for uniques binds, and O(n) for duplicates.
- Removed the need for `BuildContext` in `RefState.read`.
- Added `ReadIt` for dependency injection outside of widgets.
- Added `GetIt` migrations.
- Added `Benchmark` example.
- Added unit-tests & widget-tests.

## 0.6.0

- Added `context.init`.
- Added `context.dispose`.
- Added `AsyncRef.allReady`.
- Added `AsyncRef.allReadySync`.
- Added `AsyncRef.isReady`.
- Added `AsyncRef.isReadySync`.

## 0.5.0

- Added `MultiProvider` migration.
- Added `Consumer` migration.
- Added `ChangeNotifierProvider` migration.
- Added `ListenableProvider` migration.
- Added `ChangeNotifierWatcher`.
- Improved abstractions injection.
- Updated `README.md`.

## 0.4.0

- Added `AsyncRefState.ready()`.
- Added `context.readAsync()`.
- Added `AsyncSnapshotExtension`: when/maybeWhen & getters.
- Added `Param.isFuture`.
- Improved `FutureRef` to resolve immediately.
- Improved `Injector.call` to handle futures.
- Improved `ProvideIt.provide` initialization.

## 0.3.0

- Added `AsyncRef` & `context.reload()`.
- Added `errorBuilder` to `ProvideIt`.
- Added `loadingBuilder` to `ProvideIt`.
- Added `context.provideFactory()`.
- Added `context.provideValue()`.
- Added `FutureRef` & `context.future()`.
- Added `StreamRef` & `context.stream()`.
- Added `ProvideIt.allowedDuplicates` for duplicate rules.
- Added `Watcher.canUpdate`.
- Improved `Injector` for efficient parsing.
- Improved `ContextReaders` for efficient lookup.

## 0.2.0

- Changed `ProvideIt.root` to `ProvideIt`.
- Added `provide_it/injector.dart` library.
- Added `Injector` & `Param` for auto-injection.
- Improved all `provide` methods with auto-injection.
- Added `ProvideLazyRef` & `context.provideLazy`.
- Added `Watcher` for custom watching.
- Added `ProvideIt.watchers` with `DefaultWatchers`.
- Added `ProvideIt.namedLocator`. for injecting parameters.
- Added `CreateRef` & `context.create`.

## 0.1.0

- Changed `Provider` to `ProvideIt.root`.
- Improved ref dispose/removal on hot-reload.
- Improved several `toString` for debugging.
- Added several `asserts` for debugging.
- Added `readIt` locator.
- Added `Ref.debugValue` for debugging.
- Added `ProvideIt.log` for debugging.
- Added `RefState.removeDependent`.
- Added `dependOnInheritedElement` for bind accessors.
- Removed the need for `RefState._garbageCollector`.

## 0.0.1

- Initial release.
