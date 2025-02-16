# Changelog

## 0.3.0

- WIP Added `get_it` methods as deprecations for retro-compatibility.
- WIP Added `provider` widgets as deprecations for retro-compatibility.
- WIP Added `FutureRef` & `context.future`.
- WIP Added `StreamRef` & `context.stream`.
- WIP Added `init` to `ProvideIt.root`.
- WIP Added `dispose` to `ProvideIt.root`.
- WIP Added `errorBuilder` to `ProvideIt.root`.
- WIP Added `loadingBuilder` to `ProvideIt.root`.
- WIP Added `ProvideInstanceRef` & `context.provideInstance`.
- WIP Added `ProvideFactoryRef` & `context.provideFactory`.
- WIP Now `provide` methods support `Future` & `Stream`.
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
