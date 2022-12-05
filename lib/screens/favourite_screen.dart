import 'package:todoapp/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

class FavouriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilteredTasksBloc, FilteredTasksState>(
        builder: (context, state) {
      if (state is FilteredTasksLoadInProgress) {
        return Scaffold(
          appBar: AppBar(
            title: Text(FlutterBlocLocalizations.of(context)!.appTitle),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      } else if (state is FilteredTasksLoadSuccess) {
        final user = state.user;
        final tasks = state.allTasks;
        List<Task> favTasks = tasks.where((task) => task.favourite).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(FlutterBlocLocalizations.of(context)!.appTitle),
          ),
          drawer: AppDrawer(tasks: tasks, user: user),
          body: ViewTask(tasks: favTasks),
        );
      } else {
        return Scaffold(
          appBar: AppBar(
            title: Text(FlutterBlocLocalizations.of(context)!.appTitle),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      }
    });
  }
}
