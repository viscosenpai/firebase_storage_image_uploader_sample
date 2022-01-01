import 'dart:io';

import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String uid = '';

  @override
  void initState() {
    anonymousLoginAndFirestoreRegist();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: ElevatedButton(
          onPressed: () async {
            String path = await getLocalFilePath();
            File file = File(path);
            String filename = basename(file.path);
            print(path);
            print(filename);
            await uploadFile(path, filename);
          },
          child: const Text('Image Upload'),
        ),
      )),
    );
  }
}

Future<void> addFilePath(
    String userId, String localPath, String remotePath) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(userId).set({
    'localPath': localPath,
    'remotePath': remotePath,
  }, SetOptions(merge: true));
}

Future<void> uploadFile(String sourcePath, String uploadFileName) async {
  User? user = FirebaseAuth.instance.currentUser;
  String uid = '';
  if (user != null) {
    uid = user.uid;
  }
  final FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref().child("images"); //保存するフォルダ

  File file = File(sourcePath);
  UploadTask task = ref.child(uploadFileName).putFile(file);

  try {
    var snapshot = await task;
    await addFilePath(uid, sourcePath, snapshot.ref.fullPath);
  } catch (FirebaseException) {
    //エラー処理
  }
}

Future<String> getLocalFilePath() async {
  FileType _type = FileType.image;
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: _type,
  );
  String filePath = '';

  if (result != null) {
    File file = File(result.files.single.path!);
    filePath = file.path;
  } else {
    // User canceled the picker
  }
  return filePath;
}

Future<void> anonymousLoginAndFirestoreRegist() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  if (user == null) {
    UserCredential userCredential = await auth.signInAnonymously();
    user = userCredential.user;
    firestore
        .collection('users')
        .add({'uid': user!.uid})
        .then((value) => {print('user regist $value')})
        .catchError((error) => print("Failed to add user: $error"));
  }
}
