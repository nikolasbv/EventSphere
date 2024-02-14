import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventsphere/widgets/ticket_card.dart';
import 'package:eventsphere/widgets/layout.dart';

class UserTicketsPage extends StatefulWidget {
  final String eventId;

  const UserTicketsPage({
    super.key,
    required this.eventId,
  });

  @override
  _UserTicketsPageState createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const PageTemplate(
        showBackButton: true,
        showCameraIcon: true,
        showProfileIcon: true,
        mode: PageMode.userMode,
        activeNavItem: NavItem.none,
        bodyContent: Center(child: Text('You are not logged in.')),
      );
    }

    Stream<QuerySnapshot> ticketsStream = FirebaseFirestore.instance
        .collection('tickets')
        .where('eventId', isEqualTo: widget.eventId)
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('isValidated', descending: false)
        .snapshots();

    return PageTemplate(
      showBackButton: true,
      showCameraIcon: true,
      showProfileIcon: true,
      mode: PageMode.userMode,
      activeNavItem: NavItem.none,
      bodyContent: Container(
        color: Colors.blue[800],
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              color: Colors.blue[800],
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: const Text(
                'These are your tickets for this specific event. '
                'Please select a ticket card to validate! '
                'Make sure you have NFC enabled on your device '
                'before selecting a ticket card.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ticketsStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ticketsData = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: ticketsData.length,
                    itemBuilder: (context, index) {
                      final ticketId = ticketsData[index].id;

                      return TicketCard(
                        ticketId: ticketId,
                        eventId: widget.eventId,
                        userId: currentUser!.uid,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
