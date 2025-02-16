# Changelog

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
