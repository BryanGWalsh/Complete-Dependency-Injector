import 'injector_token_creation_source_enum.dart';
import 'injector_token_interface.dart';

class InjectorToken implements InjectorTokenInterface {
  final String _tokenStringRepresentation;
  final InjectorTokenCreationSourceEnum _tokenCreationSource;
  static int _uniqueTokenCreationIdentifierCounter = 1;

  InjectorToken.fromCounter()
      : _tokenStringRepresentation = "counter_$_uniqueTokenCreationIdentifierCounter",
        _tokenCreationSource = InjectorTokenCreationSourceEnum.counter{
    _uniqueTokenCreationIdentifierCounter++;
  }

  InjectorToken.fromString(String identifier)
      : _tokenStringRepresentation = "string_$identifier",
        _tokenCreationSource = InjectorTokenCreationSourceEnum.string;

  InjectorToken.fromType(Type classType)
      : _tokenStringRepresentation = "type_$classType-${classType.hashCode}",
        _tokenCreationSource = InjectorTokenCreationSourceEnum.classType;

  static InjectorToken fromTokenOrType(Object tokenOrInjectableClass){
    if(tokenOrInjectableClass.runtimeType == InjectorToken) return tokenOrInjectableClass as InjectorToken;
    return InjectorToken.fromType(tokenOrInjectableClass as Type);
  }
  @override
  String get tokenRepresentation => _tokenStringRepresentation;
}