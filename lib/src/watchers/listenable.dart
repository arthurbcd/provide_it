import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  const ListenableWatcher();

  @override
  void init(Listenable value, VoidCallback listener) {
    value.addListener(listener);
  }

  @override
  void cancel(Listenable value, VoidCallback listener) {
    value.removeListener(listener);
  }

  @override
  void dispose(Listenable value) {
    if (value is ChangeNotifier) {
      value.dispose();
    }
  }
}
