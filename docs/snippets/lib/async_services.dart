// Samples for docs/use-cases/async-services.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

// #region database
class Database with InjectableWithReadyMixin {
  Database() {
    _open();
  }

  static final Factory = InjectableFactory.withoutDependencies<Database>(
    () => Database(),
  );
  static final DefaultProvider = Provider(Database);

  bool isOpen = false;

  Future<void> _open() async {
    // Stand-in for real async work: opening a file, a socket, a connection pool.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    isOpen = true;
    // Tell the injector this service is ready to hand out.
    setInjectableReadyResult(true);
  }

  Future<List<String>> query(String sql) async => ['Ada', 'Grace'];
}
// #endregion database

// #region repository
class UserRepository {
  UserRepository(this._db) : dbWasOpenWhenCreated = _db.isOpen;

  static final Factory = InjectableFactory.withDependencies<UserRepository>(
    DependencyDataBuilder.list([Database]),
    (deps) => UserRepository(deps.get<Database>()),
  );
  static final DefaultProvider = Provider(UserRepository);

  final Database _db;
  final bool dbWasOpenWhenCreated;

  Future<List<String>> allUsers() => _db.query('SELECT name FROM users');
}
// #endregion repository

Future<Map<String, Object>> runAsyncServices() async {
  // #region use
  final injector = Injector([
    Database.DefaultProvider,
    UserRepository.DefaultProvider,
  ]);
  injector.registerFactories([Database.Factory, UserRepository.Factory]);

  // Completes only after Database has called setInjectableReadyResult(true),
  // so UserRepository never sees a closed database.
  final users = await injector.getService<UserRepository>();
  print(users.dbWasOpenWhenCreated); // true
  print(await users.allUsers()); // [Ada, Grace]
  // #endregion use

  final result = {
    'dbWasOpen': users.dbWasOpenWhenCreated,
    'users': await users.allUsers(),
  };
  await injector.dispose();
  return result;
}
