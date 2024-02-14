import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserEventDetails extends StatefulWidget {
  final String eventId;
  final EventCardType cardType;

  const UserEventDetails(
      {super.key, required this.eventId, required this.cardType});

  @override
  _UserEventDetailsState createState() => _UserEventDetailsState();
}

class _UserEventDetailsState extends State<UserEventDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _event;
  Set<String> _likedEvents = {};
  Set<String> _dislikedEvents = {};
  Set<String> _bookmarkedEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('Users').doc(currentUser.uid).get();
        _likedEvents = Set.from(userSnapshot['likedEvents'] ?? []);
        _dislikedEvents = Set.from(userSnapshot['dislikedEvents'] ?? []);
        _bookmarkedEvents = Set.from(userSnapshot['bookmarkedEvents'] ?? []);

        DocumentSnapshot eventSnapshot =
            await _firestore.collection('events').doc(widget.eventId).get();
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

  Future<void> _updateUserPreferences(
      String eventId, String field, bool add) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentReference userDocRef =
          _firestore.collection('Users').doc(currentUser.uid);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
        if (userSnapshot.exists) {
          List<dynamic> userPreferences = List.from(userSnapshot[field] ?? []);
          if (add) {
            userPreferences.add(eventId);
          } else {
            userPreferences.remove(eventId);
          }
          transaction.update(userDocRef, {field: userPreferences});
        }
      });
      setState(() {
        if (add) {
          switch (field) {
            case 'likedEvents':
              _likedEvents.add(eventId);
              _dislikedEvents.remove(eventId);
              break;
            case 'dislikedEvents':
              _dislikedEvents.add(eventId);
              _likedEvents.remove(eventId);
              break;
            case 'bookmarkedEvents':
              _bookmarkedEvents.add(eventId);
              break;
          }
        } else {
          switch (field) {
            case 'likedEvents':
              _likedEvents.remove(eventId);
              break;
            case 'dislikedEvents':
              _dislikedEvents.remove(eventId);
              break;
            case 'bookmarkedEvents':
              _bookmarkedEvents.remove(eventId);
              break;
          }
        }
      });
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
    bool isLiked = _likedEvents.contains(eventId);
    bool isDisliked = _dislikedEvents.contains(eventId);
    bool isBookmarked = _bookmarkedEvents.contains(eventId);

    String overview = _event?['overview'] ?? 'No Overview';
    String description = _event?['description'] ?? 'No Description';
    String cost = _event?['price']?.toString() ?? 'No Cost';
    String category = _event?['category'] ?? 'No Category';
    String availableTickets =
        _event?['availability']?.toString() ?? 'Not Available';
    bool disabledFriendly = _event?['isDisabledFriendly'] ?? false;

    return PageTemplate(
      showBackButton: true,
      showCameraIcon: true,
      showProfileIcon: true,
      isDetails: true,
      mode: PageMode.userMode,
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
                cardType: widget.cardType,
                availableTickets: event['availability'] ?? 0,
                initialThumbUpSelected: isLiked,
                initialThumbDownSelected: isDisliked,
                initialBookmarkSelected: isBookmarked,
                isNavigationEnabled: false,
                initialLikeState: isLiked,
                initialDislikeState: isDisliked,
                initialBookmarkState: isBookmarked,
                onLikePressed: () =>
                    _updateUserPreferences(eventId, 'likedEvents', !isLiked),
                onDislikePressed: () => _updateUserPreferences(
                    eventId, 'dislikedEvents', !isDisliked),
                onBookmarkPressed: () => _updateUserPreferences(
                    eventId, 'bookmarkedEvents', !isBookmarked),
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
