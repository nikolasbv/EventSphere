import 'package:eventsphere/pages/creator_ticket_validation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:eventsphere/pages/user_home_page.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:eventsphere/Authenticate/register.dart';
import 'package:eventsphere/Authenticate/authenticate.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  _CreatorProfileScreenState createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
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
            emailController.text = data['email'] ?? 'No email';
            isLoading = false;
          });
        } else {
          print('Document does not exist on the database');
          setState(() {
            isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        isLoading = false;
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
      showCameraIcon: false,
      showProfileIcon: false,
      mode: PageMode.creatorMode,
      activeNavItem: NavItem.none,
      bodyContent: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.blue[800],
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: isEditing
                          ? _buildEditableFields()
                          : _buildDisplayFields(),
                    ),
                    _buildActionButton('Validate Tickets', context, () async {
                      bool nfcAvailable =
                          await NfcManager.instance.isAvailable();
                      if (nfcAvailable) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreatorTicketValidation()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enable NFC to proceed.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }),
                    _buildActionButton('Switch to User Mode', context, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserHomePage()),
                      );
                    }),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[800],
              child: Text(
                usernameController.text.isNotEmpty
                    ? usernameController.text[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white),
              ),
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
}
