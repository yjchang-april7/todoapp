import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../../resources/repository.dart';
import '../../authentication/authentication_bloc.dart';
import '../../authentication/authentication_event.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final UserRepositoryFlutter userRepository;
  final AuthenticationBloc authenticationBloc;

  RegistrationBloc({
    required this.userRepository,
    required this.authenticationBloc,
  })  : assert(userRepository != null),
        assert(authenticationBloc != null),
        super(RegistrationInitial()) {
    on<RegistrationEvent>(
      (event, emit) async {
        if (event is RegistrationButtonPressed) {
          print("registration.RegistraionButtonPressed");
          emit(RegistrationLoading());

          try {
            print("registration.RegistraionButtonPressed.signup");
            await userRepository.signup(
                event.email!, event.password!, event.name!, event.phone!);
            authenticationBloc.add(LoggedIn());
            print("registration.RegistraionButtonPressed.loggedin");
            emit(RegistrationInitial());
          } catch (e) {
            print(e);
            emit(RegistrationFailure(error: e.toString()));
          }
        }
      },
    );
  }

  // Stream<RegistrationState> mapEventToState(RegistrationEvent event) async* {
  //   if (event is RegistrationButtonPressed) {
  //     print("mapEventToState registration.RegistraionButtonPressed");
  //     emit(RegistrationLoading());

  //     try {
  //       print("mapEventToState registration.RegistraionButtonPressed.signup");
  //       await userRepository?.signup(
  //           event.email!, event.password!, event.name!, event.phone!);
  //       authenticationBloc?.add(LoggedIn());
  //       print("mapEventToState registration.RegistraionButtonPressed.loggedin");
  //       emit(RegistrationInitial());
  //     } catch (e) {
  //       print(e);
  //       emit(RegistrationFailure(error: e.toString()));
  //     }
  //   }
  // }
}
