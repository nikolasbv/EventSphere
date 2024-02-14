import 'package:flutter/material.dart';
import 'event_creation.dart';
import 'package:eventsphere/widgets/layout.dart';

class CreatorHomePage extends StatelessWidget {
  const CreatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: false,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.creatorMode,
      activeNavItem: NavItem.home,
      bodyContent: Container(
        color: Colors.blue[800],
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EventCreationPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Create an Event',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Creator Mode:',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Here you will be able to create, save and preview your own events',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Event Creation Instructions:',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '• Locate and tap the Create an Event button above.\n'
                          '• You will be directed to a new page with a form to fill out the details of your event.\n',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Enter the information needed in the corresponding fields. Here are some things to watch out:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '• Location: Specify the event\'s location. Give the address street and number as well as the city of the event.\n'
                          '• Category: Choose the category that best describe your event (e.g., Sports, Music, Education).\n'
                          '• Price: If the event is free, leave the price option empty or set it to 0.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
