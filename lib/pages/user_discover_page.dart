import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dart_geohash/dart_geohash.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _nearbyEvents = [];
  Set<String> _likedEvents = {};
  Set<String> _dislikedEvents = {};
  Set<String> _bookmarkedEvents = {};
  static const double searchRadius = 10000;

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
    _determinePosition();
  }

  Future<void> _fetchUserPreferences() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('Users').doc(currentUser.uid).get();
        setState(() {
          _likedEvents = Set.from(userSnapshot['likedEvents'] ?? []);
          _bookmarkedEvents = Set.from(userSnapshot['bookmarkedEvents'] ?? []);
          _dislikedEvents = Set.from(userSnapshot['dislikedEvents'] ?? []);
        });
        //_determinePosition();
      } catch (e) {
        print('Error fetching user preferences: $e');
      }
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('Location Services Enabled: $serviceEnabled');
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      _showLocationServiceMessage('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    print('Initial Permission: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        _showLocationServiceMessage('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      _showLocationServiceMessage(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _fetchNearbyEvents(position);
  }

  Future<void> _fetchNearbyEvents(Position position) async {
    setState(() => _isLoading = true);
    DateTime now = DateTime.now();

    String currentGeohash =
        GeoHasher().encode(position.latitude, position.longitude);
    String geohashPrefix = currentGeohash.substring(0, 1);

    var snapshot = await _firestore
        .collection('events')
        .where('geohash', isGreaterThanOrEqualTo: geohashPrefix)
        .where('geohash', isLessThan: geohashPrefix + '\uf8ff')
        .get();

    List<DocumentSnapshot> filteredEvents = [];

    for (var doc in snapshot.docs) {
      var event = doc.data();
      double? eventLat = event['latitude'];
      double? eventLong = event['longitude'];
      Timestamp? eventTimestamp = event['date'];

      if (eventLat != null && eventLong != null && eventTimestamp != null) {
        double distanceInMeters = Geolocator.distanceBetween(
            position.latitude, position.longitude, eventLat, eventLong);
        DateTime eventDate = eventTimestamp.toDate();

        if (distanceInMeters <= searchRadius && eventDate.isAfter(now)) {
          filteredEvents.add(doc);
        }
      }
    }

    setState(() {
      _nearbyEvents = filteredEvents;
      _isLoading = false;
    });
    print("Finished fetching and filtering events");
  }

  void _showLocationServiceMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLikePressed(String eventId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentReference userDocRef =
            _firestore.collection('Users').doc(currentUser.uid);
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
          if (userSnapshot.exists) {
            List<dynamic> likedEvents =
                List.from(userSnapshot['likedEvents'] ?? []);
            List<dynamic> dislikedEvents =
                List.from(userSnapshot['dislikedEvents'] ?? []);

            dislikedEvents.remove(eventId);

            if (likedEvents.contains(eventId)) {
              likedEvents.remove(eventId);
              _likedEvents.remove(eventId);
            } else {
              likedEvents.add(eventId);
              _likedEvents.add(eventId);
            }

            transaction.update(userDocRef,
                {'likedEvents': likedEvents, 'dislikedEvents': dislikedEvents});

            setState(() {});
          }
        });
      } catch (e) {
        print('Error updating liked events: $e');
      }
    }
  }

  Future<void> _onDislikePressed(String eventId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentReference userDocRef =
            _firestore.collection('Users').doc(currentUser.uid);
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
          if (userSnapshot.exists) {
            List<dynamic> dislikedEvents =
                List.from(userSnapshot['dislikedEvents'] ?? []);
            List<dynamic> likedEvents =
                List.from(userSnapshot['likedEvents'] ?? []);

            likedEvents.remove(eventId);

            if (dislikedEvents.contains(eventId)) {
              dislikedEvents.remove(eventId);
              _dislikedEvents.remove(eventId);
            } else {
              dislikedEvents.add(eventId);
              _dislikedEvents.add(eventId);
            }

            transaction.update(userDocRef,
                {'likedEvents': likedEvents, 'dislikedEvents': dislikedEvents});

            setState(() {});
          }
        });
      } catch (e) {
        print('Error updating disliked events: $e');
      }
    }
  }

  Future<void> _onBookmarkPressed(String eventId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentReference userDocRef =
            _firestore.collection('Users').doc(currentUser.uid);
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
          if (userSnapshot.exists) {
            List<dynamic> bookmarkedEvents =
                List.from(userSnapshot['bookmarkedEvents'] ?? []);

            if (bookmarkedEvents.contains(eventId)) {
              bookmarkedEvents.remove(eventId);
            } else {
              bookmarkedEvents.add(eventId);
            }

            transaction
                .update(userDocRef, {'bookmarkedEvents': bookmarkedEvents});
          }
        });
      } catch (e) {
        print('Error updating bookmarked events: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: false,
      showCameraIcon: true,
      showProfileIcon: true,
      mode: PageMode.userMode,
      activeNavItem: NavItem.discover,
      bodyContent: Container(
        color: Colors.blue[800],
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Find Events Near You!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Here you will find events that are near to you based'
                ' on your location! Make sure you have the '
                'location enabled on your device!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _nearbyEvents.length,
                      itemBuilder: (context, index) {
                        var event =
                            _nearbyEvents[index].data() as Map<String, dynamic>;
                        DateTime eventDateTime =
                            (event['date'] as Timestamp).toDate();
                        String formattedDate =
                            DateFormat('dd/MM/yy').format(eventDateTime);
                        String formattedTime =
                            DateFormat('HH:mm').format(eventDateTime);

                        String eventId = event['eventID'];
                        bool isLiked = _likedEvents.contains(eventId);
                        bool isDisliked = _dislikedEvents.contains(eventId);
                        bool isBookmarked = _bookmarkedEvents.contains(eventId);

                        return EventCard(
                          eventId: eventId,
                          imageUrl: event['imageURL'],
                          eventTime: formattedTime,
                          eventDate: formattedDate,
                          eventTitle: event['title'],
                          eventHeader: event['header'],
                          eventLocation:
                              '${event['streetName']} ${event['streetNumber']}, ${event['city']}',
                          eventDescription: event['overview'],
                          eventCost: event['price'].toString(),
                          avatarText: event['creatorFirstLetter'],
                          cardType: EventCardType.book,
                          availableTickets: event['availability'],
                          initialThumbUpSelected: isLiked,
                          initialThumbDownSelected: isDisliked,
                          initialBookmarkSelected: isBookmarked,
                          isNavigationEnabled: true,
                          initialLikeState: isLiked,
                          initialDislikeState: isDisliked,
                          initialBookmarkState: isBookmarked,
                          onLikePressed: () => _onLikePressed(eventId),
                          onDislikePressed: () => _onDislikePressed(eventId),
                          onBookmarkPressed: () => _onBookmarkPressed(eventId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
