import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;
  String? typingId;
  // dynamic messages;
  Timer? _timer;
  late User user;
  TextEditingController controller = TextEditingController();
  void getCurrentUser() {
    user = _auth.currentUser!;
    print(user.email);
  }

  // void getMessages() async {
  //   messages = await _fireStore.collection('messages').get();
  //   setState(() {});
  //   for (var item in messages.docs) {
  //     print(item['text']);
  //   }
  // }

  @override
  void initState() {
    getCurrentUser();

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          Text('${user.email}'),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, LoginScreen.id, (route) => false);
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder(
                stream: _fireStore.collection('typing_users').snapshots(),
                builder: (context, snapShot) {
                  if (snapShot.hasData) {
                    List<dynamic> users = snapShot.data!.docs;
                    return ListView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          if (users[index]['user'] != user.email) {
                            return Container(
                                color: Colors.amberAccent,
                                child: Text('${users[index]['user']}'));
                          }
                          return SizedBox();
                        });
                  }
                  return const SizedBox();
                }),
            SizedBox(
              height: 24,
            ),
            StreamBuilder(
                stream: _fireStore
                    .collection('messages')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapShot) {
                  if (snapShot.hasData) {
                    List<dynamic> messages = snapShot.data!.docs;

                    return Expanded(
                      child: ListView.builder(
                          reverse: true,
                          shrinkWrap: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(
                                messages: messages,
                                index: index,
                                sender: messages[index]['sender'],
                                isMe: messages[index]['sender'] == user.email);
                          }),
                    );
                  }
                  return Text('loading data ..');
                }),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: kMessageTextFieldDecoration,
                      onChanged: (value) async {
                        if (_timer?.isActive ?? false) _timer?.cancel();
                        _timer =
                            Timer(const Duration(milliseconds: 500), () async {
                          if (value.isNotEmpty) {
                            if (typingId == null) {
                              final ref = await _fireStore
                                  .collection('typing_users')
                                  .add({'user': user.email});
                              typingId = ref.id;
                            }
                          } else if (controller.text.isEmpty) {
                            _fireStore
                                .collection('typing_users')
                                .doc(typingId)
                                .delete();
                            typingId = null;
                          }
                        });
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //Implement send functionality.
                      if (controller.text.isNotEmpty) {
                        _fireStore.collection('messages').add(
                          {
                            'text': controller.text,
                            'sender': user.email,
                            'time': DateTime.now(),
                          },
                        );
                        controller.clear();
                        if (typingId != null) {
                          _fireStore
                              .collection('typing_users')
                              .doc(typingId)
                              .delete();
                          typingId = null;
                        }
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {Key? key,
      required this.messages,
      required this.index,
      required this.sender,
      required this.isMe})
      : super(key: key);

  final List messages;
  final int index;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            '$sender',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Material(
            color: isMe ? Colors.blueAccent : Colors.lightBlueAccent,
            borderRadius: isMe
                ? BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${messages[index]['text']}',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
