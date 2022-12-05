import 'dart:async';

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import '../../authentication/authentication_event.dart';
import '../../authentication/authentication_bloc.dart';
import '../../resources/repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepositoryFlutter userRepository;
  final AuthenticationBloc authenticationBloc;

  LoginBloc({
    required this.userRepository,
    required this.authenticationBloc,
  })  : assert(userRepository != null),
        assert(authenticationBloc != null),
        super(LoginInitial()) {
    on<LoginEvent>((event, emit) => _LoginEvent(event, emit));
  }

  void _LoginEvent(LoginEvent event, Emitter<LoginState> emit) async {
    if (event is LoginButtonPressed) {
      emit(LoginLoading());
      try {
        await userRepository.createUserSession(event.email!, event.password!);
        authenticationBloc.add(LoggedIn());

        emit(LoginInitial());
      } catch (e) {
        emit(LoginFailure(error: e.toString()));
      }
    }
  }
}
