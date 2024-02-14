import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:eventsphere/pages/creator_home_page.dart';

class EventQRCodeScreen extends StatelessWidget {
  final String eventId;

  const EventQRCodeScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImageView(
              data: eventId,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan this QR code to view the event details.\n'
              'You can take a screenshot of this QR code.\n'
              'This QR code will automatically be placed in your event details screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreatorHomePage()));
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue[800],
                backgroundColor: Colors.grey[50],
                fixedSize: const Size(200, 40),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              child: const Text('Return to Home Page'),
            ),
          ],
        ),
      ),
    );
  }
}
