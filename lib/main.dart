import 'package:flutter/material.dart';
import 'package:flutter_oauth2/CallbackPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart'; // Import url_launcher
import 'dart:html' as html; // Import for web-specific functionality

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OAuth2 Login',
      home: LoginPage(),
      routes: {
        '/callback': (context) => CallbackPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String _authUrl = ''; // Store the authorization URL

  // Replace with your Spring Boot Auth Server details
  final String _clientId = 'oidc-client'; // Your client ID
  final String _clientSecret = 'secret'; // Your client secret
  final String _authServerBaseUrl =
      'http://localhost:9000'; // Base URL of your auth server
  final String _redirectUri =
      'http://localhost:8080/callback'; // Your redirect URI (e.g., your-app-scheme://callback)
  final String _scopes = 'openid'; // Requested scopes

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Construct Authorization URL
    _authUrl =
        '$_authServerBaseUrl/oauth2/authorize?response_type=code&client_id=$_clientId&redirect_uri=$_redirectUri&scope=$_scopes&code_challenge=yOsDH-qh5AvOEgJ4_opxfc-nFE9TKj_CD4XAOl7_Wq4&code_challenge_method=S256';
    print('Authorization URL  : $_authUrl');
    // 2. Launch Authorization URL in Browser
    // if (await canLaunchUrlString(_authUrl)) {
    //   await launchUrlString(_authUrl,
    //       mode: LaunchMode.externalApplication); // Use externalApplication
    // } else {
    //   setState(() {
    //     _isLoading = false;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Could not launch $_authUrl')),
    //   );
    //   return;
    // }

    html.window.open(_authUrl, '_self'); // Or '_blank' for a new window

    // 3. Listen for messages from your web server (callback page)
    html.window.onMessage.listen((html.MessageEvent event) {
      print(event.origin);
      if (event.origin == 'http://localhost:8080/') {
        // Check the origin! VERY IMPORTANT
        String authorizationCode = event.data; // The authorization code
        print(authorizationCode);
        _exchangeCodeForToken(authorizationCode);
      } else {
        print(
            'Message from unexpected origin: ${event.origin}'); // Security check!
      }
    });

    print("Reached the end");

    // 3. Handle Callback (This part is tricky and platform-dependent.  See explanation below)
    // You'll need a way to intercept the redirect.  This usually involves:
    //    a. Custom URL Scheme (for mobile)
    //    b. Deep Linking (for mobile)
    //    c. A small web server (less common for mobile, but possible for web)

    // Example (Conceptual - adapt to your callback mechanism):
    // Assume you receive the authorization code in a callback URL like:
    // your-redirect-uri/?code=the_authorization_code

    //  ***** IMPORTANT *****
    //  The code below is illustrative. You *MUST* implement the actual callback handling
    //  using a method appropriate to your target platform (Android, iOS, Web).

    // Example - Replace with your actual callback handling logic
    //  (This example assumes you have somehow received the auth code)
    // String authorizationCode = 'the_authorization_code_from_callback'; // Replace with the actual code from callback
    // _exchangeCodeForToken(authorizationCode); // After you get the code, exchange it for a token
  }

  Future<void> _exchangeCodeForToken(String authorizationCode) async {
    final String tokenUrl = '$_authServerBaseUrl/oauth2/token';

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': authorizationCode,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _accessToken = responseData['access_token'];
      _refreshToken = responseData['refresh_token'];

      setState(() {
        _isLoading = false;
      });

      // Store tokens securely (e.g., using flutter_secure_storage)
      print('Access Token: $_accessToken');
      print('Refresh Token: $_refreshToken');

      // Navigate to the next screen or update UI
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during token exchange')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OAuth2 Login'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
      ),
    );
  }
}
