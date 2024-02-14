import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreatorEventDetails extends StatefulWidget {
  final String eventId;
  final EventCardType cardType;

  const CreatorEventDetails(
      {super.key, required this.eventId, required this.cardType});

  @override
  _CreatorEventDetailsState createState() => _CreatorEventDetailsState();
}

class _CreatorEventDetailsState extends State<CreatorEventDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _event;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot eventSnapshot;
        if (widget.cardType == EventCardType.published) {
          eventSnapshot =
              await _firestore.collection('events').doc(widget.eventId).get();
        } else if (widget.cardType == EventCardType.saved) {
          eventSnapshot = await _firestore
              .collection('savedEvents')
              .doc(widget.eventId)
              .get();
        } else {
          throw Exception('Invalid card type for event details');
        }

        if (eventSnapshot.exists) {
          setState(() {
            _event = eventSnapshot;
          });
        }
      } catch (e) {
        print('Error fetching event data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    var event = _event!.data() as Map<String, dynamic>;
    DateTime eventDateTime = (event['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('dd/MM/yy').format(eventDateTime);
    String formattedTime = DateFormat('HH:mm').format(eventDateTime);
    String streetName = event['streetName'] ?? '';
    String streetNumber = event['streetNumber']?.toString().trim() ?? '';
    String city = event['city'] ?? '';

    String location = streetName;
    if (streetNumber.isNotEmpty &&
        streetNumber != 'No Street Number' &&
        streetNumber != '0') {
      location += ' $streetNumber';
    }
    location += ', $city';
    String eventId = _event!.id;

    String overview = _event?['overview'] ?? 'No Overview';
    String description = _event?['description'] ?? 'No Description';
    String cost = _event?['price']?.toString() ?? 'No Cost';
    String category = _event?['category'] ?? 'No Category';
    String availableTickets =
        _event?['availability']?.toString() ?? 'Not Available';
    bool disabledFriendly = _event?['isDisabledFriendly'] ?? false;

    return PageTemplate(
      showBackButton: true,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.creatorMode,
      activeNavItem: NavItem.none,
      bodyContent: Container(
        color: Colors.blue[800],
        child: SingleChildScrollView(
          child: Column(
            children: [
              EventCard(
                eventId: eventId,
                imageUrl: event['imageURL'] ?? 'https://picsum.photos/536/354',
                eventTime: formattedTime,
                eventDate: formattedDate,
                eventTitle: event['title'] ?? 'No title',
                eventHeader: event['header'],
                eventLocation: location,
                eventDescription: event['overview'] ?? 'No description',
                eventCost: event['price']?.toString() ?? 'Free',
                avatarText: event['creatorFirstLetter'] ?? '',
                cardType: EventCardType.book,
                availableTickets: event['availability'] ?? 0,
                isNavigationEnabled: false,
                isPreview: true,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAttributeText('Overview:', overview),
                    const SizedBox(height: 12),
                    _buildAttributeText('Description:', description),
                    const SizedBox(height: 12),
                    _buildAttributeText('Place:', location),
                    const SizedBox(height: 12),
                    _buildAttributeText('Time:', formattedTime),
                    const SizedBox(height: 12),
                    _buildAttributeText('Date:', formattedDate),
                    const SizedBox(height: 12),
                    _buildAttributeText(
                        'Cost:', cost == 'Free' ? 'Free' : '$cost Euros'),
                    const SizedBox(height: 12),
                    _buildAttributeText('Category:', category),
                    const SizedBox(height: 12),
                    _buildAttributeText('Available Tickets:', availableTickets),
                    const SizedBox(height: 12),
                    _buildAttributeText(
                        'Disabled Friendly:', disabledFriendly ? 'Yes' : 'No'),
                    if (widget.cardType == EventCardType.published) ...[
                      const SizedBox(height: 30),
                      Center(
                        child: QrImageView(
                          data: widget.eventId,
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: false,
                          errorStateBuilder: (cxt, err) {
                            return Container(
                              child: const Center(
                                child: Text(
                                  "Uh oh! Something went wrong...",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "Scan this QR code to view the event details.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeText(String attributeName, String attributeValue,
      [String? unit]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$attributeName ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16.0,
              ),
            ),
            TextSpan(
              text: attributeValue,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontSize: 16.0,
              ),
            ),
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
