import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:eventsphere/widgets/layout.dart';

class CreatorTicketValidation extends StatefulWidget {
  const CreatorTicketValidation({super.key});

  @override
  _CreatorTicketValidationState createState() =>
      _CreatorTicketValidationState();
}

class _CreatorTicketValidationState extends State<CreatorTicketValidation> {
  void _startNFCReading() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        debugPrint('NFC is available.');
        NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
          debugPrint('NFC Tag Detected: ${tag.data}');
        });
      } else {
        debugPrint('NFC not available.');
      }
    } catch (e) {
      debugPrint('Error reading NFC: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: true,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.creatorMode,
      activeNavItem: NavItem.none,
      bodyContent: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.blue[800],
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Here you can validate tickets from your created event.'
                        ' Make sure you have NFC enebled on your device.'
                        ' To validate an event press the button below.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _startNFCReading,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue[800],
                        backgroundColor: Colors.grey[50],
                        fixedSize: const Size(140, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                      ), //,
                      child: const Text('Validate Ticket'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/nfc.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
