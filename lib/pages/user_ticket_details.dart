import 'package:flutter/material.dart';
import 'package:eventsphere/widgets/ticket_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserTicketDetails extends StatefulWidget {
  final String ticketId;
  final String eventId;
  final String userId;

  const UserTicketDetails({
    super.key,
    required this.ticketId,
    required this.eventId,
    required this.userId,
  });

  @override
  _UserTicketDetailsState createState() => _UserTicketDetailsState();
}

class _UserTicketDetailsState extends State<UserTicketDetails> {
  String? fetchedUserId;

  @override
  void initState() {
    super.initState();
    fetchedUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startNFCWriting() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        debugPrint('NFC Available');
        NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
          debugPrint('Session started');
          try {
            debugPrint('Waiting');
            NdefMessage message =
                NdefMessage([NdefRecord.createText('Ticket Validated')]);
            await Ndef.from(tag)?.write(message);
            debugPrint('Ticket Data Written Successfully');
            NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('Error writing to NFC: $e');
            NfcManager.instance.stopSession();
          }
        });
      } else {
        debugPrint('NFC not available.');
      }
    } catch (e) {
      debugPrint('Error with NFC: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: true,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.userMode,
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
                        'Ready to validate your ticket? Hold your device near the NFC reader to validate. Make sure you have NFC enabled on your device!',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TicketCard(
                      ticketId: widget.ticketId,
                      eventId: widget.eventId,
                      userId: widget.userId,
                      isNavigable: false,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startNFCWriting,
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
}
