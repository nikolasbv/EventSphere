import 'package:flutter/material.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:eventsphere/pages/creator_home_page.dart';
import 'package:eventsphere/pages/user_bookmarked_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventsphere/pages/notification_service.dart';
import 'package:eventsphere/Authenticate/authenticate.dart';
import 'package:eventsphere/Authenticate/register.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isEditing = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          Map<String, dynamic> data =
              documentSnapshot.data() as Map<String, dynamic>;
          setState(() {
            usernameController.text = data['username'] ?? 'No username';
            emailController.text = currentUser.email ?? 'No email';
          });
        } else {
          print('Document does not exist on the database');
        }
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: true,
      showCameraIcon: true,
      showProfileIcon: false,
      mode: PageMode.userMode,
      activeNavItem: NavItem.none,
      bodyContent: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.blue[800],
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child:
                    isEditing ? _buildEditableFields() : _buildDisplayFields(),
              ),
              _buildActionButton('Bookmarked Events', context, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserBookmarkedEvents()),
                );
              }),
              _buildActionButton('Switch to Creator Mode', context, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreatorHomePage()),
                );
              }),
              //_buildNotificationButton(),
              _buildActionButton('Log Out', context, _handleLogout),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final AuthService authService = AuthService();
    await authService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildDisplayFields() {
    String initialLetter = usernameController.text.isNotEmpty
        ? usernameController.text[0].toUpperCase()
        : 'U';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[800],
              child: Text(initialLetter,
                  style: const TextStyle(color: Colors.white)),
            ),
            const Expanded(
              child: Center(
                child: Text('User Info', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildEditableInfoField('Username:', usernameController.text),
        _buildEditableInfoField('Email:', emailController.text),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.blue[800],
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue[800],
          child: const Text('E', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (FirebaseAuth.instance.currentUser != null) {
                  String userId = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .update({
                    'username': usernameController.text,
                  }).then((_) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Success'),
                        content: const Text('Username updated successfully'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    setState(() {
                      isEditing = false;
                    });
                  }).catchError((error) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Failed to update username'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue[800],
                backgroundColor: Colors.grey[50],
                fixedSize: const Size(140, 40),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              child: const Text('Submit Changes'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue[800],
                backgroundColor: Colors.grey[50],
                fixedSize: const Size(140, 40),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, BuildContext context, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 3.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.blue[800],
          backgroundColor: Colors.grey[50],
          padding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 3.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          NotificationService.showNotification(
            1,
            'Test Notification',
            'This is a test notification.',
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.blue[800],
          backgroundColor: Colors.grey[50],
          padding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        child: const Text('Show Notification', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
