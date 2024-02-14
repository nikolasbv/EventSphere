import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatorTicketValidation extends StatefulWidget {
  const CreatorTicketValidation({super.key});

  @override
  _CreatorTicketValidationState createState() =>
      _CreatorTicketValidationState();
}

class _CreatorTicketValidationState extends State<CreatorTicketValidation> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                      onPressed: _startNfcSession,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue[800], backgroundColor: Colors.grey[50], fixedSize: const Size(140, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      child: const Text('Validate Event'),
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

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('NFC is not enabled. Please enable NFC and try again.')),
      );
      return;
    }

    NfcManager.instance.startSession(
        invalidateAfterFirstRead: false,
        onDiscovered: (NfcTag tag) async {
          var ndef = Ndef.from(tag);
          if (ndef == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The NFC tag is empty.')),
            );
            return;
          }

          List<NdefRecord> records = ndef.cachedMessage?.records ?? [];
          String ticketId = String.fromCharCodes(records[0].payload);
          String eventId = String.fromCharCodes(records[1].payload);
          String userId = String.fromCharCodes(records[2].payload);

          await _validateTicket(ticketId, eventId, userId);
        });
  }

  Future<void> _validateTicket(
      String ticketId, String eventId, String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(currentUser?.uid).get();
    List<dynamic> publishedEvents = userDoc['publishedEvents'] ?? [];

    if (!publishedEvents.contains(eventId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event was not created by you.')),
      );
      return;
    }

    var ticketSnapshot =
        await _firestore.collection('tickets').doc(ticketId).get();

    if (ticketSnapshot.exists) {
      var ticketData = ticketSnapshot.data();
      if (ticketData?['eventId'] == eventId &&
          ticketData?['userId'] == userId) {
        if (!ticketData?['isValidated']) {
          await _firestore
              .collection('tickets')
              .doc(ticketId)
              .update({'isValidated': true});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket validated successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This ticket has already been validated.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket validation failed. Data mismatch.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket not found.')),
      );
    }

    NfcManager.instance.stopSession();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}
