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
    _writeNfc(context);
  }

  Future<void> _writeNfc(BuildContext context) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "NFC is not available. Please go back, enable NFC, and return here to validate your ticket."),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    NfcManager.instance.startSession(
        invalidateAfterFirstRead: false,
        onDiscovered: (NfcTag tag) async {
          var ndef = Ndef.from(tag);

          if (ndef == null || !ndef.isWritable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("NFC tag is not writable."),
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          NdefRecord ticketIdRecord = NdefRecord.createText(widget.ticketId);
          NdefRecord eventIdRecord = NdefRecord.createText(widget.eventId);
          NdefRecord userIdRecord = NdefRecord.createText(widget.userId);

          NdefMessage message =
              NdefMessage([ticketIdRecord, eventIdRecord, userIdRecord]);

          try {
            await ndef.write(message);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("NFC data written successfully."),
                duration: Duration(seconds: 3),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error writing NFC data: $e"),
                duration: const Duration(seconds: 3),
              ),
            );
          } finally {
            NfcManager.instance.stopSession();
          }
        });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
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
              color:
                  Colors.blue[800], 
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
