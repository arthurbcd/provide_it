import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  const ListenableWatcher();

  @override
  void init(Listenable observable, VoidCallback listener) {
    observable.addListener(listener);
  }

  @override
  void cancel(Listenable observable, VoidCallback listener) {
    observable.removeListener(listener);
  }

  @override
  void dispose(Listenable observable) {
    if (observable is ChangeNotifier) {
      observable.dispose();
    }
  }
}
