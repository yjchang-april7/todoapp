import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../resources/repository.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TasksRepositoryFlutter tasksRepository;
  final UserRepositoryFlutter? userRepository;

  TasksBloc({required this.tasksRepository, this.userRepository})
      : super(TasksLoadInProgress()) {
    on<TasksEvent>((event, emit) => _TasksEvent(event, emit));
  }

  // ignore: non_constant_identifier_names
  void _TasksEvent(TasksEvent event, Emitter<TasksState> emit) async {
    if (event is TasksLoaded) {
      emit(await _mapTasksLoadedToState());
    } else if (event is TaskAdded) {
      emit(await _mapTaskAddedToState(event));
    } else if (event is TaskUpdated) {
      emit(await _mapTaskUpdatedToState(event));
      if (state is TasksLoadSuccess) {
        _updateTasksOnAppwrite(event.task.id, event.task);
      }
    } else if (event is TaskDeleted) {
      emit(await _mapTaskDeletedToState(event));
      if (state is TasksLoadSuccess) {
        _deleteTasksFromAppwrite(event.task.id);
      }
    }
  }

  Future<TasksState> _mapTasksLoadedToState() async {
    print("_mapTasksLoadedToState");
    try {
      final users = await tasksRepository.getUserInfo();
      print("s _mapTasksLoadedToState.loadTasks");
      final tasks = await tasksRepository.loadTasks();
      print(tasks);
      print("e _mapTasksLoadedToState.loadTasks");

      return (TasksLoadSuccess(
          tasks!.map(Task.fromEntity).toList(), User.fromEntity(users)));
    } catch (_) {
      print("_mapTasksLoadedToState.error");
      return (TasksLoadFailure());
    }
  }

  Future<TasksState> _mapTaskAddedToState(TaskAdded event) async {
    print("_mapTaskAddedToState");
    if (state is TasksLoadSuccess) {
      await _saveTasksToAppwrite(event.task);
      final List<Task> updatedTasks =
          List.from((state as TasksLoadSuccess).tasks.reversed.toList())
            ..add(event.task);
      final User user = (state as TasksLoadSuccess).user!;
      return TasksLoadSuccess(updatedTasks.reversed.toList(), user);
    } else {
      print("_mapTaskAddedToState.error");
      return (TasksLoadFailure());
    }
  }

  Future<TasksState> _mapTaskUpdatedToState(TaskUpdated event) async {
    print("_mapTaskUpdatedToState");
    if (state is TasksLoadSuccess) {
      final User user = (state as TasksLoadSuccess).user!;
      final List<Task> updatedTasks =
          (state as TasksLoadSuccess).tasks.map((task) {
        return task.id == event.task.id ? event.task : task;
      }).toList();
      return TasksLoadSuccess(updatedTasks, user);
    } else {
      print("_mapTaskUpdatedToState.error");
      return (TasksLoadFailure());
    }
  }

  Future<TasksState> _mapTaskDeletedToState(TaskDeleted event) async {
    print("_mapTaskDeletedToState");
    if (state is TasksLoadSuccess) {
      final updatedTasks = (state as TasksLoadSuccess)
          .tasks
          .where((task) => task.id != event.task.id)
          .toList();
      final User user = (state as TasksLoadSuccess).user!;
      return TasksLoadSuccess(updatedTasks, user);
    } else {
      print("_mapTaskDeletedToState.error");
      return (TasksLoadFailure());
    }
  }

  Future _saveTasksToAppwrite(Task tasks) {
    return tasksRepository.saveTasksToAppwrite(tasks.toEntity());
  }

  Future _deleteTasksFromAppwrite(String taskId) {
    return tasksRepository.deleteTasksFromAppwrite(taskId);
  }

  Future _updateTasksOnAppwrite(String taskId, Task tasks) {
    return tasksRepository.updateTasksOnAppwrite(taskId, tasks.toEntity());
  }
}
