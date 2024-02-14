import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/pages/user_ticket_details.dart';
import 'package:nfc_manager/nfc_manager.dart';

class TicketCard extends StatelessWidget {
  final String ticketId;
  final String eventId;
  final String userId;
  final bool isNavigable;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.eventId,
    required this.userId,
    this.isNavigable = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('events').doc(eventId).get(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError || !eventSnapshot.data!.exists) {
            return const Center(child: Text('Event not found'));
          }

          var eventData = eventSnapshot.data!.data() as Map<String, dynamic>;

          String imageUrl =
              eventData['imageURL'] ?? 'https://picsum.photos/200';
          String eventTime = DateFormat('HH:mm')
              .format((eventData['date'] as Timestamp).toDate());
          String eventDate = DateFormat('dd/MM/yyyy')
              .format((eventData['date'] as Timestamp).toDate());
          String eventLocation =
              '${eventData['city']}, ${eventData['streetName']}';
          String eventTitle = eventData['title'];
          String avatarText = eventData['creatorFirstLetter'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('tickets')
                .doc(ticketId)
                .get(),
            builder: (context, ticketSnapshot) {
              if (ticketSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ticketSnapshot.hasError) {
                return Center(child: Text('Error: ${ticketSnapshot.error}'));
              }

              if (!ticketSnapshot.hasData || !ticketSnapshot.data!.exists) {
                return const Center(child: Text('Ticket not found'));
              }

              var ticketData =
                  ticketSnapshot.data!.data() as Map<String, dynamic>;

              String bookingDate = ticketData['bookingDate'] != null
                  ? DateFormat('dd/MM/yyyy')
                      .format((ticketData['bookingDate'] as Timestamp).toDate())
                  : 'N/A';

              bool isValidated = ticketData['isValidated'] ?? false;
              String validation = isValidated ? 'Yes' : 'No';

              return InkWell(
                  onTap: () async {
                    if (isNavigable) {
                      bool nfcAvailable =
                          await NfcManager.instance.isAvailable();

                      if (isValidated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('This ticket has already been validated.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else if (nfcAvailable) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserTicketDetails(
                              ticketId: ticketId,
                              eventId: eventId,
                              userId: userId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enable NFC to proceed.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          SmallEventCard(
                            eventId: eventId,
                            imageUrl: imageUrl,
                            eventTime: eventTime,
                            eventDate: eventDate,
                            eventLocation: eventLocation,
                            eventTitle: eventTitle,
                            avatarText: avatarText,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Booking Name:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(ticketData['fullName'] ?? 'N/A'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Booked On:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(bookingDate),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Validated:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(validation),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Tickets:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${ticketData['totalTickets']}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Cost:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${ticketData['totalCost']}€'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ticket ID:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(ticketId),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          );
        });
  }
}
