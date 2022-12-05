import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoapp/blocs/filtered_tasks/filtered_tasks_bloc.dart';
import 'package:todoapp/blocs/tasks/tasks_bloc.dart';
import 'package:todoapp/models/task.dart';
import 'package:todoapp/screens/task_details_screen.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

class ViewTask extends StatelessWidget {
  final List<Task>? tasks;
  ViewTask({Key? key, this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: (Colors.grey[300])!,
                    offset: Offset(1, 1),
                    blurRadius: 4),
              ]),
              child: ListTile(
                leading: Icon(
                  Icons.search,
                  color: Colors.blue,
                ),
                title: TextField(
                  onChanged: (value) {
                    print(value);
                    BlocProvider.of<FilteredTasksBloc>(context)
                        .add(SearchTasks(searchTerm: value));
                  },
                  decoration: InputDecoration(
                    hintText: "Search by Task Name",
                    border: InputBorder.none,
                  ),
                ),
                trailing: Icon(
                  Icons.filter_list,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            key: TasksKeys.taskList,
            itemCount: tasks?.length,
            itemBuilder: (BuildContext context, int index) {
              final task = tasks?[index];
              return TaskItem(
                task: task!,
                onDismissed: (direction) {
                  BlocProvider.of<TasksBloc>(context).add(TaskDeleted(task));
                  ScaffoldMessenger.of(context).showSnackBar(DeleteTaskSnackBar(
                      task: task,
                      onUndo: () => BlocProvider.of<TasksBloc>(context)
                          .add(TaskAdded(task))));
                },
                onTap: () async {
                  final removeTask = await Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) {
                    return TaskDetailsScreen(id: task.id);
                  }));
                  if (removeTask != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(DeleteTaskSnackBar(
                      key: TasksKeys.snackbar,
                      task: task,
                      onUndo: () => BlocProvider.of<TasksBloc>(context)
                          .add(TaskAdded(task)),
                    ));
                  }
                },
                onCheckboxChanged: (_) {
                  BlocProvider.of<TasksBloc>(context).add(TaskUpdated(
                    task.copyWith(
                      complete: !task.complete,
                      favourite: task.favourite,
                      title: task.title,
                      description: task.description,
                    ),
                  ));
                },
                onFavouriteSelected: () {
                  return task.favourite
                      ? BlocProvider.of<TasksBloc>(context).add(TaskUpdated(
                          task.copyWith(
                              favourite: false,
                              title: task.title,
                              description: task.description,
                              complete: task.complete)))
                      : BlocProvider.of<TasksBloc>(context).add(
                          TaskUpdated(task.copyWith(
                              favourite: true,
                              title: task.title,
                              description: task.description,
                              complete: task.complete)),
                        );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
