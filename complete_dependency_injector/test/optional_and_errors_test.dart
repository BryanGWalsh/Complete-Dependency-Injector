import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class Settings {
  Settings(this.dsn);
  final String? dsn;
}

class Broken {}

class NeedsBroken {
  NeedsBroken(this.broken);
  final Broken broken;
}

final dsnToken = InjectorToken.fromString('optionalDsn');

void main() {
  setUpAll(() {
    Injector([]).registerFactories([
      InjectableFactory.withDependencies<Settings>(
        DependencyDataBuilder.list([dsnToken]),
        (deps) => Settings(deps.getOptional<String>(dsnToken)),
      ),
      InjectableFactory.withoutDependencies<Broken>(() => throw StateError('factory failed')),
      InjectableFactory.withDependencies<NeedsBroken>(
        DependencyDataBuilder.list([Broken]),
        (deps) => NeedsBroken(deps.get<Broken>()),
      ),
    ]);
  });

  test('an optional dependency nothing provides resolves to null', () async {
    final injector = Injector([Provider(Settings)]);
    final settings = await injector.getService<Settings>();
    expect(settings.dsn, isNull);
  });

  test('an optional dependency that is provided is passed in', () async {
    final injector = Injector([Provider(Settings), Provider.value(dsnToken, 'dsn://x')]);
    final settings = await injector.getService<Settings>();
    expect(settings.dsn, 'dsn://x');
  });

  test('getServiceOrNull returns null when nothing provides the type', () async {
    final injector = Injector([]);
    expect(await injector.getServiceOrNull<Settings>(), isNull);
  });

  test('a failing factory deep in the graph surfaces as an error, not a hang', () async {
    final injector = Injector([Provider(NeedsBroken), Provider(Broken)]);
    await expectLater(
      injector.getService<NeedsBroken>().timeout(const Duration(seconds: 2)),
      throwsA(isA<StateError>()),
    );
  });
}
