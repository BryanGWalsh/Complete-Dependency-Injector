import 'package:complete_dependency_injector/complete_dependency_injector.dart';

class MyService {
  void sayHello() => print('Hello from MyService!');
}

void main() async {
  final injector = Injector([
    Provider(MyService),
  ]);

  injector.registerFactory(
    InjectableFactory.withoutDependencies<MyService>(() => MyService()),
  );

  final service = await injector.getService<MyService>();
  service.sayHello();
}
