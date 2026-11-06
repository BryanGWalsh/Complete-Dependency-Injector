import 'dart:async';

import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

final debugOptions = InjectorDebugOptions(allowFactoryReplacement: true);

/// Records the order in which services are disposed.
final List<String> disposeLog = [];

class Tracked implements InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async {
    disposeCount++;
    disposeLog.add('Tracked');
  }
}

abstract class Repo {}

class RepoImpl implements Repo, InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

class Database implements InjectableWithDisposeInterface {
  bool closed = false;
  @override
  Future<void> dispose() async {
    closed = true;
    disposeLog.add('Database');
  }
}

/// Flushes to its database when disposed, so the database must still be open.
class Cache implements InjectableWithDisposeInterface {
  final Database db;
  bool flushedToOpenDb = false;
  Cache(this.db);
  @override
  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    flushedToOpenDb = !db.closed;
    disposeLog.add('Cache');
  }
}

class Broken {}

class SlowStart with InjectableWithReadyMixin {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

void main() {
  setUp(disposeLog.clear);

  test('disposing a parent disposes its child scopes', () async {
    final root = Injector([], debugOptions: debugOptions);
    root.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    final child = Injector([Provider(Tracked)], parent: root);
    final service = await child.getService<Tracked>();

    await root.dispose();

    expect(service.disposeCount, 1);
  });

  test('a disposed child is released by its parent and not disposed again', () async {
    final root = Injector([], debugOptions: debugOptions);
    root.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    final child = Injector([Provider(Tracked)], parent: root);
    final service = await child.getService<Tracked>();

    await child.dispose();
    await root.dispose();

    expect(service.disposeCount, 1);
  });

  test('an instance reached through fromDerived is disposed once', () async {
    final injector = Injector([Provider.factory(Repo, fromDerived: RepoImpl)], debugOptions: debugOptions);
    injector.registerFactory(InjectableFactory.withoutDependencies<RepoImpl>(() => RepoImpl()));
    final repo = await injector.getService<Repo>() as RepoImpl;

    await injector.dispose();

    expect(repo.disposeCount, 1);
  });

  test('an instance reached through alias tokens is disposed once', () async {
    final alias = InjectorToken.fromString('tracked-alias');
    final injector = Injector([Provider(Tracked, aliasTokens: [alias])], debugOptions: debugOptions);
    injector.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    final service = await injector.getService<Tracked>();
    await injector.getService<Tracked>(alias);

    await injector.dispose();

    expect(service.disposeCount, 1);
  });

  test('disposing twice disposes services once', () async {
    final injector = Injector([Provider(Tracked)], debugOptions: debugOptions);
    injector.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    final service = await injector.getService<Tracked>();

    await injector.dispose();
    await injector.dispose();

    expect(service.disposeCount, 1);
  });

  test('getService after dispose throws instead of returning a disposed instance', () async {
    final injector = Injector([Provider(Tracked)], debugOptions: debugOptions);
    injector.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    await injector.getService<Tracked>();
    await injector.dispose();

    expect(() => injector.getService<Tracked>(), throwsA(isA<InjectorError>()));
    expect(() => injector.getServiceOrNull<Tracked>(), throwsA(isA<InjectorError>()));
  });

  test('a child of a disposed parent cannot resolve through it', () async {
    final root = Injector([Provider(Tracked)], debugOptions: debugOptions);
    root.registerFactory(InjectableFactory.withoutDependencies<Tracked>(() => Tracked()));
    final child = Injector([], parent: root);
    await root.dispose();

    expect(() => child.getService<Tracked>(), throwsA(isA<InjectorError>()));
  });

  test('a service is disposed before the services it depends on', () async {
    final injector = Injector([Provider(Database), Provider(Cache)], debugOptions: debugOptions);
    injector.registerFactories([
      InjectableFactory.withoutDependencies<Database>(() => Database()),
      InjectableFactory.withDependencies<Cache>(DependencyDataBuilder.positional([Database]).done(), (d) => Cache(d<Database>())),
    ]);
    final cache = await injector.getService<Cache>();

    await injector.dispose();

    expect(cache.flushedToOpenDb, isTrue);
    expect(disposeLog, ['Cache', 'Database']);
  });

  test('a factory that failed does not stop dispose or the other disposals', () async {
    final injector = Injector([Provider(Broken), Provider(Tracked)], debugOptions: debugOptions);
    injector.registerFactories([
      InjectableFactory.withoutDependencies<Broken>(() => throw StateError('boom')),
      InjectableFactory.withoutDependencies<Tracked>(() => Tracked()),
    ]);
    final service = await injector.getService<Tracked>();
    await expectLater(injector.getService<Broken>(), throwsA(isA<StateError>()));

    await injector.dispose();

    expect(service.disposeCount, 1);
  });

  test('a service still being created when dispose starts is disposed', () async {
    final injector = Injector([Provider(SlowStart)], debugOptions: debugOptions);
    final slow = SlowStart();
    injector.registerFactory(InjectableFactory.withoutDependencies<SlowStart>(() => slow));
    final pending = injector.getService<SlowStart>();
    final disposing = injector.dispose();
    slow.setInjectableReadyResult(true);

    final service = await pending;
    await disposing;
    expect(service.disposeCount, 1);
  });
}
