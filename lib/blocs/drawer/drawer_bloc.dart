import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../resources/repository.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final TasksBloc tasksBloc;
  final UserRepositoryFlutter? userRepository;
  final TasksRepositoryFlutter? tasksRepository;

  // final DrawerTab drawerTab;
  StreamSubscription<TasksState>? tasksSubscription;

  DrawerBloc(
      {required this.tasksBloc, this.userRepository, this.tasksRepository})
      : assert(tasksBloc != null),
        assert(userRepository != null),
        assert(tasksRepository != null),
        super(DrawerLoadInProgress()) {
    tasksSubscription = tasksBloc.stream.listen(
      (state) {
        if (state is TasksLoadSuccess) {
          add(DrawerUpdated(state.tasks));
        }
      },
    );
    on<DrawerEvent>((event, emit) => _DrawerEvent(event, emit));
  }

  void _DrawerEvent(DrawerEvent event, Emitter<DrawerState> emit) async {
    if (event is DrawerUpdated) {
      try {
        //Think of how to load this information once the user login for better performance
        final users = await userRepository!.getUserInfo();
        final tasks = await tasksRepository!.loadTasks();
        final email = users!.email;
        final name = users.name;
        final phone = users.phone;

        int numFavourite =
            tasks!.where((task) => task.favourite).toList().length;
        int numTasks = tasks.length;
        int numComplete = tasks.where((task) => task.complete).toList().length;
        int numPlanned = 23;
        int numMyDay = 5;
        emit(DrawerLoadSuccess(numFavourite, numComplete, numPlanned, numMyDay,
            numTasks, email, name, phone));
      } on AppwriteException catch (e, st) {
        print(e.message);
      }
    }
  }

  @override
  Future<void> close() {
    tasksSubscription!.cancel();
    return super.close();
  }
}
