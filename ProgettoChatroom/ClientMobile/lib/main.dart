import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  Socket? socket;
  bool connected = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  List<String> messages = [];
  String myUsername = '';

  void connect() async {
    String username = usernameController.text.trim();
    if (username.isEmpty) return;

    try {
      socket = await Socket.connect('192.168.1.18', 3000);
    } catch (e) {
      return;
    }

    if (socket == null) return;

    socket!.write(username + '\n');
    myUsername = username;

    setState(() {
      connected = true;
      messages.add('SYSTEM: sei entrato come $myUsername');
    });

    socket!.listen((data) {
      String text = String.fromCharCodes(data).trim();
      if (text.isEmpty) return;

      setState(() {
        if (text.startsWith(myUsername + ':')) {
          messages.add('Me: ' + text.substring(myUsername.length + 1));
        } else {
          messages.add(text);
        }
      });
    }, onDone: () {
      setState(() {
        messages.add('SYSTEM: connessione chiusa');
        connected = false;
      });
      if (socket != null) {
        socket!.close();
      }
    });
  }

  void sendMessage() {
    String text = messageController.text.trim();
    if (text.isEmpty) return;
    if (connected == false) return;
    if (socket == null) return;

    socket!.write(text + '\n');
    messageController.clear();
  }

  @override
  void dispose() {
    if (socket != null) {
      socket!.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Mobile')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (connected == false) ...[
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              ElevatedButton(
                onPressed: connect,
                child: Text('Connetti'),
              ),
            ],
            if (connected == true)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          String msg = messages[index];
                          bool isMe = msg.startsWith('Me:');

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.symmetric(vertical: 2),
                              color: isMe ? Colors.blue[200] : Colors.green[200],
                              child: Text(msg),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            onSubmitted: (value) => sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: sendMessage,
                        )
                      ],
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
