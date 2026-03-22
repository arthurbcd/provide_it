class User {}

typedef TypeOf<T> = T;

void main() {
  final a = Symbol('a');
  final b = Symbol('a');
  final c = #a;

  print(identical(a, b));
  print(identical(a, c));
  print(a == b);
  print(a == c);

  print('a: $a, b: $b');
}
