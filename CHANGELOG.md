# Changelog

- WIP Improve ErrorBuilder

# 0.6.0

- Added `context.init`. 0.5.1
- Added `context.dispose`. 0.5.1

# 0.5.0

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
- Added `context.allReady()`.
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
