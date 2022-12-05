import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoapp/authentication/authentication.dart';
import 'package:todoapp/blocs/blocs.dart';
import 'package:todoapp/localization/task_localization.dart';
import 'package:todoapp/resources/repository.dart';
import 'package:todoapp/screens/home_screen.dart';
import 'package:todoapp/screens/screens.dart';
import 'package:todoapp/utils/utils.dart';

import 'models/models.dart';
import 'widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Client client = Client();
  client.setEndpoint(WebClient.API_ENDPOINT).setProject(WebClient.PROJECT_ID);
  final UserRepositoryFlutter userRepository =
      UserRepositoryFlutter(webClient: WebClient(client: client));
  final TasksRepositoryFlutter taskRepository =
      TasksRepositoryFlutter(webClient: WebClient(client: client));

  Bloc.observer = SimpleBlocObserver();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<AuthenticationBloc>(
        create: (context) => AuthenticationBloc(
          userRepository: userRepository,
        )..add(AppStarted()),
      ),
      BlocProvider(create: (context) {
        return TasksBloc(
          tasksRepository: taskRepository,
        )..add(TasksLoaded());
      })
    ],
    child: TaskApp(
      userRepository: userRepository,
      taskRepository: taskRepository,
      arguments: ScreenArguments([]),
    ),
  ));
}

class TaskApp extends StatelessWidget {
  final UserRepository _userRepository;
  final TasksRepositoryFlutter _tasksRepository;
  final ScreenArguments arguments;

  const TaskApp(
      {Key? key,
      @required userRepository,
      @required taskRepository,
      required this.arguments})
      : assert(userRepository != null),
        _userRepository = userRepository,
        _tasksRepository = taskRepository,
        super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          AppTheme.isLightTheme ? Brightness.dark : Brightness.light,
      statusBarBrightness:
          AppTheme.isLightTheme ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          AppTheme.isLightTheme ? Colors.white : Colors.black,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness:
          AppTheme.isLightTheme ? Brightness.dark : Brightness.light,
    ));
    return MaterialApp(
      title: FlutterBlocLocalizations().appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      localizationsDelegates: [
        TaskLocalizationsDelegate(),
        FlutterBlocLocalizationsDelegate(),
      ],
      routes: {
        TaskRoutes.home: (context) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, state) {
            print("state => ");
            print(state);
            if (state is AuthenticationAuthenticated) {
              return MultiBlocProvider(providers: [
                BlocProvider<DrawerBloc>(
                  create: (context) => DrawerBloc(
                    tasksBloc: BlocProvider.of<TasksBloc>(context),
                    userRepository: _userRepository as UserRepositoryFlutter,
                    tasksRepository: _tasksRepository,
                  ),
                ),
                BlocProvider<FilteredTasksBloc>(
                  create: (context) => FilteredTasksBloc(
                    tasksBloc: BlocProvider.of<TasksBloc>(context)
                      ..add(TasksLoaded()),
                    tasksRepository: _tasksRepository,
                    userRepository: _userRepository as UserRepositoryFlutter,
                  ),
                ),
              ], child: HomeScreen());
            }
            if (state is AuthenticationUnauthenticated) {
              print('AuthenticationUnauthenticated');
              return WelcomeScreen(userRepository: _userRepository);
            }
            if (state is AuthenticationLoading) {
              print('AuthenticationLoading');
              return SplashScreen();
            }
            return WelcomeScreen(userRepository: _userRepository);
          });
        },
        TaskRoutes.addTask: (context) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, state) {
            if (state is AuthenticationAuthenticated) {
              return AddEditTaskScreen(
                  key: TasksKeys.addTaskScreen,
                  onSave: (title, description, dueDateTime) async {
                    BlocProvider.of<TasksBloc>(context).add(
                      TaskAdded(
                        Task(title,
                            description: description,
                            dueDateTime: dueDateTime,
                            uid: (await _userRepository.getCurrentUser())!),
                      ),
                    );
                  },
                  isEditing: false);
            }
            if (state is AuthenticationUnauthenticated) {
              return WelcomeScreen(userRepository: _userRepository);
            }
            if (state is AuthenticationLoading) {
              return SplashScreen();
            }
            return WelcomeScreen(userRepository: _userRepository);
          });
        },
        TaskRoutes.viewTasks: (context) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, state) {
            if (state is AuthenticationAuthenticated) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider<DrawerBloc>(
                    create: (context) => DrawerBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      userRepository: _userRepository as UserRepositoryFlutter,
                      tasksRepository: _tasksRepository,
                    ),
                  ),
                  BlocProvider<FilteredTasksBloc>(
                    create: (context) => FilteredTasksBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      tasksRepository: _tasksRepository,
                      userRepository: _userRepository as UserRepositoryFlutter,
                    ),
                  ),
                ],
                child: ViewTaskScreen(),
              );
            }
            if (state is AuthenticationUnauthenticated) {
              return WelcomeScreen(userRepository: _userRepository);
            }
            if (state is AuthenticationLoading) {
              return SplashScreen();
            }
            return WelcomeScreen(userRepository: _userRepository);
          });
        },
        TaskRoutes.favouriteTasks: (context) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              if (state is AuthenticationAuthenticated) {
                return MultiBlocProvider(providers: [
                  BlocProvider<DrawerBloc>(
                    create: (context) => DrawerBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      userRepository: _userRepository as UserRepositoryFlutter,
                      tasksRepository: _tasksRepository,
                    ),
                  ),
                  BlocProvider<FilteredTasksBloc>(
                    create: (context) => FilteredTasksBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      tasksRepository: _tasksRepository,
                      userRepository: _userRepository as UserRepositoryFlutter,
                    ),
                  ),
                ], child: FavouriteScreen());
              }
              if (state is AuthenticationUnauthenticated) {
                return WelcomeScreen(userRepository: _userRepository);
              }
              if (state is AuthenticationLoading) {
                return SplashScreen();
              }
              return WelcomeScreen(userRepository: _userRepository);
            },
          );
        },
        TaskRoutes.completedTasks: (context) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              if (state is AuthenticationAuthenticated) {
                return MultiBlocProvider(providers: [
                  BlocProvider<DrawerBloc>(
                    create: (context) => DrawerBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      userRepository: _userRepository as UserRepositoryFlutter,
                      tasksRepository: _tasksRepository,
                    ),
                  ),
                  BlocProvider<FilteredTasksBloc>(
                    create: (context) => FilteredTasksBloc(
                      tasksBloc: BlocProvider.of<TasksBloc>(context),
                      tasksRepository: _tasksRepository,
                      userRepository: _userRepository as UserRepositoryFlutter,
                    ),
                  ),
                ], child: CompleteTaskScreen());
              }
              if (state is AuthenticationUnauthenticated) {
                return WelcomeScreen(userRepository: _userRepository);
              }
              if (state is AuthenticationLoading) {
                return SplashScreen();
              }
              return WelcomeScreen(userRepository: _userRepository);
            },
          );
        },
      },
    );
  }
}
