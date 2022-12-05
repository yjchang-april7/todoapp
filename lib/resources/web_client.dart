import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:meta/meta.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import '../models/models.dart';

class WebClient {
  static const API_ENDPOINT = "http://datalk.local:10088/v1";
  final Client client = Client();

  static const PROJECT_ID = "63844b1173926488d5a1";
  static const DATABASE_ID = "63845e8005c1d9b8a6a5";
  static const COLLECTION_ID = "63868e4b3009adfcd7ab";
  static const API_KEY =
      "d529e06e5a6292cf9110f4bc2753b48980fe7d64319fd1d3e589dbec4cdd762371cf86b5086a187565f9bf6e2b8bee4ca111477c573f343a8a7f490b8b290d75bba186d5dede48375f2231e7e167ead5d9c37fd1977438ff6f40b4f9039fcddd7e63e0e68caeea91358492119bd6f9189a1bad7ab8c38b4aa1cc3b9584c16a67";
  static const USER_COLLECTION_ID = "6388004e8f55acc7091e";
  WebClient({@required client}) : assert(client != null);

  Future<String> getCurrentUser() async {
    String uid = '';
    String? errorMessage;
    client.setEndpoint(API_ENDPOINT).setProject(PROJECT_ID);
    Account account = Account(client);
    try {
      appwrite_models.Account result = await account.get();
      uid = result.$id;
    } on AppwriteException catch (e, st) {
      print(st);
      switch (e.code.toString()) {
        case "429":
          errorMessage = "Too may request. Try again later";
          break;
        case "409":
          errorMessage = "Account Already Exists";
          break;
        case "401":
          errorMessage = "Unauthorized user";
          break;
        default:
          errorMessage = "Something went wrong";
      }
    }
    // ignore: unnecessary_null_comparison
    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
    return uid;
  }

  // Get task attached to a user.
  Future<List<TaskEntity>?> fetchTasks(String userId) async {
    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;
    Databases databases = Databases(client);
    print('fetch all task');

    try {
      final appwrite_models.DocumentList documentList =
          await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        queries: [
          Query.equal("uid", userId),
          Query.orderDesc('createdDateTime'),
        ],
      );
      print(documentList.toMap());
      final tasks = documentList.documents
          .map<TaskEntity>(
              (doc) => TaskEntity.fromJson(doc.toMap() as Map<String, Object>))
          .toList();

      return tasks;
    } on AppwriteException catch (e, st) {
      print(e.toString());
      //TODO:: display error
    }
    return null;
  }

  /// 현재 로그인 한 이용자의 정보라면 userID가 필요 없음
  /// 회원 검색은 현재 Flutter SDK에서는 제공하지 않음
  Future<UserEntity> fetchUserInfo(String userID) async {
    String? errorMessage;
    client.setEndpoint(API_ENDPOINT).setProject(PROJECT_ID);
    Account account = Account(client);
    try {
      appwrite_models.Account result = await account.get();

      return UserEntity.fromJson(result.toMap());
    } on AppwriteException catch (e, st) {
      print(st);
      switch (e.code.toString()) {
        case "429":
          errorMessage = "Too may request. Try again later";
          break;
        case "409":
          errorMessage = "Account Already Exists";
          break;
        case "401":
          errorMessage = "Unauthorized user";
          break;
        default:
          errorMessage = "Something went wrong";
      }
    }
    // ignore: unnecessary_null_comparison
    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
    return UserEntity.fromJson({});
  }

  //
  Future<List<TaskEntity>?> searchTasks(String search) async {
    final userID = await getCurrentUser();
    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;

    Databases databases = Databases(client);

    /// FULLTEXT 검색
    /// Creating one single fulltext index for each attribute works though and I can query using a Search Query for each attributes defined in the index.
    /// So to be able to use an fulltext index composed with multiple attributes I had to
    /// 1) create a fulltext index for each attributé
    /// 2) create an Index with all the attributes in it
    try {
      final appwrite_models.DocumentList documentList =
          await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        queries: [
          Query.search("uid", userID),
          Query.search("title", search),
          Query.search("description", search),
          Query.orderDesc('createdDateTime'),
        ],
      );

      print(documentList.toMap());
      final tasks = documentList.documents
          .map<TaskEntity>(
              (doc) => TaskEntity.fromJson(doc.toMap() as Map<String, Object>))
          .toList();

      return tasks;
    } on AppwriteException catch (e, st) {
      print(e.message);
      //TODO:: display error
    }
    return null;
  }

  // Save task into the database
  Future<bool> postTasks(TaskEntity task) async {
    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;

    Databases databases = Databases(client);
    try {
      final result = await databases.createDocument(
          databaseId: DATABASE_ID,
          collectionId: COLLECTION_ID,
          documentId: task.id, // ID.unique()
          data: task.toJson(),
          permissions: [
            Permission.read(Role.user(task.uid)),
            Permission.write(Role.user(task.uid)),
            Permission.delete(Role.user(task.uid)),
            Permission.update(Role.user(task.uid)),
          ]);
    } catch (e) {
      print(e.toString());
    }
    return Future.value(true);
  }

  // Delete task from the database
  Future<bool> deleteTasks(String taskId) async {
    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;

    Databases databases = Databases(client);
    String documentId = (await getDocumentID(taskId))!;

    try {
      final result = databases.deleteDocument(
          databaseId: DATABASE_ID,
          collectionId: COLLECTION_ID,
          documentId: documentId);
    } on AppwriteException catch (e, st) {
      print(e.toString());
    }

    return true;
  }

  // Update a task on the database
  Future<bool> updateTasks(String taskId, TaskEntity task) async {
    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;
    String documentId = (await getDocumentID(taskId))!;
    Databases databases = Databases(client);
    try {
      appwrite_models.Document result = await databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: documentId,
        data: task.toJson(),
      );

      print(result);
      return true;
    } catch (e) {
      print(e.toString());
    }
    return false;
  }

  // Get document id
  Future<String?> getDocumentID(String taskId) async {
    String? documentId;

    client.setEndpoint(API_ENDPOINT).setProject(PROJECT_ID); // Your project ID

    Databases databases = Databases(client);

    try {
      appwrite_models.DocumentList result = await databases.listDocuments(
          databaseId: DATABASE_ID,
          collectionId: COLLECTION_ID,
          queries: [
            Query.equal("id", taskId),
          ]);

      documentId = result.documents[0].$id;
    } catch (e) {
      print(e.toString());
      //TODO:: display error instead
      //  return documentId;
    }
    return documentId;
  }

  // Signup a user and also create an account session.
  Future<String?> signup(
      String email, String password, String name, String phone) async {
    String? uid;
    String? errorMessage;

    client
            .setEndpoint(API_ENDPOINT) // Your API Endpoint
            .setProject(PROJECT_ID) // Your project ID
        ;

    Account account = Account(client);
    print(email);
    print(password);
    print(name);
    try {
      final appwrite_models.Account result = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      print(result);
      uid = result.$id;
      if (uid != null) {
        //Create user session after succesfully signing up
        await createUserSession(email, password);

        /// Save user [email, name, phone] to appwrite
        await saveUserDetails(email, name, phone);
      }
    } on AppwriteException catch (e, st) {
      print(e.message);
      switch (e.code.toString()) {
        case "429":
          errorMessage = "Too may request. Try again later";
          break;
        case "409":
          errorMessage = "Account Already Exists";
          break;
        case "401":
          errorMessage = "Unauthorized user";
          break;
        default:
          errorMessage = "Something went wrong";
      }
    }
    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
    return uid;
  }

  // Create user session after signup
  Future<bool> createUserSession(String email, String password) async {
    String? errorMessage;
    client
        .setEndpoint(API_ENDPOINT) // Your API Endpoint
        .setProject(PROJECT_ID); // Your project ID

    Account account = Account(client);

    try {
      final appwrite_models.Session result = await account.createEmailSession(
        email: email,
        password: password,
      );
      print(result);
      return true;
    } on AppwriteException catch (e, st) {
      print(e);

      switch (e.code.toString()) {
        case "429":
          errorMessage = "Too may request. Try again later";
          break;
        case "409":
          errorMessage = "Account Already Exists";
          break;
        case "401":
          errorMessage = "Invalid email / password";
          break;
        default:
          errorMessage = "Something went wrong";
      }
    }

    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
    return false;
  }

  // Save User information into the database
  Future saveUserDetails(String email, String name, String phone) async {
    // Get current logged in user ID
    final userID = await getCurrentUser();
    client
        .setEndpoint(API_ENDPOINT) // Your API Endpoint
        .setProject(PROJECT_ID); // Your project ID

    Databases databases = Databases(client);

    try {
      await databases.createDocument(
        databaseId: DATABASE_ID,
        collectionId: USER_COLLECTION_ID,
        documentId: ID.unique(),
        data: {'uid': userID, 'email': email, 'name': name, 'phone': phone},
      );
    } on AppwriteException catch (e, st) {
      print(e.message);
    }
  }

  // Get user information
  Future<UserEntity> getUserInfo() async {
    // Get current logged in user ID
    final userID = await getCurrentUser();

    Map<String, dynamic> json = {};

    client
        .setEndpoint(API_ENDPOINT) // Your API Endpoint
        .setProject(PROJECT_ID); // Your project ID

    Databases databases = Databases(client);

    try {
      final appwrite_models.DocumentList result = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: USER_COLLECTION_ID,
        queries: [Query.equal('uid', userID)],
      );

      if (result.total > 0) {
        json = result.documents[0].toMap();
      }

      return UserEntity.fromJson(json);
    } on AppwriteException catch (e, st) {
      print(e.message);
      //TODO:: display error instead
      return UserEntity.fromJson(json);
    }
  }

  // Check if user session is active.
  Future<bool> isSignedIn() async {
    String? session = await getSession();
    if (session != null) {
      return true;
    }
    return false;
  }

  // Get current session
  Future<String?> getSession() async {
    String? sessionId;
    client
        .setEndpoint(API_ENDPOINT) // Your API Endpoint
        .setProject(PROJECT_ID); // Your project ID

    Account account = Account(client);
    try {
      final appwrite_models.Session result =
          await account.getSession(sessionId: 'current');
      sessionId = result.$id;
    } on AppwriteException catch (e, st) {
      print(e.message);
      sessionId = null;
    }
    return sessionId;
  }

  //Signout and end current session
  signOut() async {
    String? sessionId = await getSession();

    if (sessionId != null) {
      Account account = Account(client);

      client
          .setEndpoint(API_ENDPOINT) // Your API Endpoint
          .setProject(PROJECT_ID); // Your project ID

      Future result = account.deleteSession(
        sessionId: sessionId,
      );

      result.then((response) {
        print('logged out');
        print(response);
      }).catchError((error) {
        print(error.response);
      });
    }
  }
}
