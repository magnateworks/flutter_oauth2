import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';

class CallbackPage extends StatefulWidget {
  const CallbackPage({super.key});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  String? _authorizationCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print("inside callback page");

    _handleCallback();
  }

  void _handleCallback() {
    // 1. Get URL parameters (using html package)
    final Uri uri = html.window.location.href as Uri;
    final Map<String, String> params = uri.queryParameters;

    if (params.containsKey('code')) {
      _authorizationCode = params['code'];
      _sendMessageToParent(_authorizationCode!);
    } else if (params.containsKey('error')) {
      _errorMessage = params['error'];
      _sendMessageToParent(_errorMessage!); // Send the error
    } else {
      _errorMessage = 'No code or error parameter found.';
      _sendMessageToParent(_errorMessage!); // Send the error
    }
  }

  void _sendMessageToParent(String message) {
    // 2. Send the message to the parent window (Flutter web app)
    if (html.window.opener != null) {
      // Check if the parent window exists
      try {
        html.window.opener!.postMessage(message,
            'http://localhost:8080/'); // Replace with your Flutter app's origin!
        print('Message sent to parent: $message');
        // Optionally close the callback window if it was opened in a new tab
        // html.window.close();
      } catch (e) {
        print('Error sending message to parent: $e');
        setState(() {
          _errorMessage = "Error communicating with parent window: $e";
        });
      }
    } else {
      print('Parent window not found.');
      setState(() {
        _errorMessage = "Parent window not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Callback'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_authorizationCode != null)
              Text(
                'Authorization Code: $_authorizationCode',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (_errorMessage != null)
              Text('Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red)),
            const CircularProgressIndicator(), // Show a loading indicator
            const Text("Processing....")
          ],
        ),
      ),
    );
  }
}
