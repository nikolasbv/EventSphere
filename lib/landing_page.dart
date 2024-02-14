import 'package:flutter/material.dart';
import 'package:eventsphere/Authenticate/authenticate.dart';
import 'package:eventsphere/pages/creator_home_page.dart';
import 'package:eventsphere/pages/user_home_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    //NotificationService.checkAndScheduleNotifications();
    final Color darkBlue = Colors.blue[800] ?? Colors.blue;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
                left: 16.0, top: 24.0, right: 16.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png', width: 50),
                    const SizedBox(width: 8),
                    Text(
                      'EventSphere',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.exit_to_app, color: darkBlue),
                  onPressed: () async {
                    final AuthService authService = AuthService();
                    await authService.signOut();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: darkBlue,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UserHomePage()));
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: darkBlue,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('User Mode'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreatorHomePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: darkBlue,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Creator Mode'),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to EventSphere: Discover Nearby!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Choose your mode to get started:',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'User Mode:',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              Text(
                                'Explore a diverse range of events happening near you.\n'
                                'Bookmark events you’re interested in to keep them on your radar.\n'
                                'Secure your spot by booking tickets directly through the app.',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Creator Mode:',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              Text(
                                'Bring your event ideas to life by creating and managing them on our platform.\n'
                                'Save drafts of your events and come back to edit them anytime.\n'
                                'Publish your events to connect with attendees and grow your audience.',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: darkBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
