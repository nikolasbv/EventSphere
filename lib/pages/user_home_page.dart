import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:eventsphere/widgets/search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _myEvents = [];
  Set<String> _likedEvents = {};
  Set<String> _userBookmarkedEvents = {};
  Set<String> _dislikedEvents = {};
  Set<String> _userHomeEvents = {};
  String _searchQuery = '';
  String _selectedCategory = 'None';
  String _selectedLocation = 'None';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
  }

  Future<void> _fetchUserPreferences() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('Users').doc(currentUser.uid).get();
        setState(() {
          _likedEvents = Set.from(userSnapshot['likedEvents'] ?? []);
          _userBookmarkedEvents =
              Set.from(userSnapshot['bookmarkedEvents'] ?? []);
          _dislikedEvents = Set.from(userSnapshot['dislikedEvents'] ?? []);
          _userHomeEvents = Set.from(userSnapshot['homeEvents'] ?? []);
        });
        _fetchMyEvents();
      } catch (e) {
        print('Error fetching user preferences: $e');
      }
    }
  }

  Future<void> _fetchMyEvents() async {
    Set<String> homeEventIds = Set.from(_userHomeEvents);
    DateTime now = DateTime.now();

    List<DocumentSnapshot> futureHomeEventsDocs = [];
    for (var eventId in homeEventIds) {
      DocumentSnapshot eventSnapshot =
          await _firestore.collection('events').doc(eventId).get();
      if (eventSnapshot.exists &&
          (eventSnapshot['date'] as Timestamp).toDate().isAfter(now)) {
        futureHomeEventsDocs.add(eventSnapshot);
      }
    }

    QuerySnapshot allEventsSnapshot =
        await _firestore.collection('events').get();
    List<DocumentSnapshot> futureOtherEventsDocs = allEventsSnapshot.docs
        .where((doc) =>
            !homeEventIds.contains(doc.id) &&
            (doc['date'] as Timestamp).toDate().isAfter(now))
        .toList();

    List<DocumentSnapshot> combinedFutureEvents = []
      ..addAll(futureHomeEventsDocs)
      ..addAll(futureOtherEventsDocs);

    setState(() {
      _myEvents = combinedFutureEvents;
    });
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
      activeNavItem: NavItem.home,
      bodyContent: Container(
        color: Colors.blue[800],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: SearchBarWithFilters(
                onSearchChanged: _onSearchQueryChanged,
                onCategoryChanged: _onCategoryChanged,
                onLocationChanged: _onLocationChanged,
                onDateChanged: _onDateChanged,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _myEvents.length,
                itemBuilder: (context, index) {
                  String eventId = _myEvents[index].id;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return CircularProgressIndicator();
                      }
                      var event = snapshot.data!.data() as Map<String, dynamic>;
                      DateTime eventDateTime =
                          (event['date'] as Timestamp).toDate();
                      String formattedDate =
                          DateFormat('dd/MM/yy').format(eventDateTime);
                      String formattedTime =
                          DateFormat('HH:mm').format(eventDateTime);
                      String location = event['streetName'] ?? '';
                      String streetNumber =
                          event['streetNumber']?.toString().trim() ?? '';
                      String city = event['city'] ?? '';
                      if (streetNumber.isNotEmpty &&
                          streetNumber != 'No Street Number' &&
                          streetNumber != '0') {
                        location += ' $streetNumber';
                      }
                      location += ', $city';

                      bool isLiked = _likedEvents.contains(eventId);
                      bool isDisliked = _dislikedEvents.contains(eventId);
                      bool isBookmarked =
                          _userBookmarkedEvents.contains(eventId);

                      return EventCard(
                        eventId: eventId,
                        imageUrl: event['imageURL'] ??
                            'https://picsum.photos/536/354',
                        eventTime: formattedTime,
                        eventDate: formattedDate,
                        eventTitle: event['title'] ?? 'No title',
                        eventHeader: event['header'] ?? 'No header',
                        eventLocation: location,
                        eventDescription: event['overview'] ?? 'No description',
                        eventCost: event['price']?.toString() ?? 'Free',
                        avatarText: event['creatorFirstLetter'] ?? '',
                        cardType: EventCardType.book,
                        availableTickets: event['availability'] ?? 0,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _fetchFilteredMyEvents();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _fetchFilteredMyEvents();
    });
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
      _fetchFilteredMyEvents();
    });
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _fetchFilteredMyEvents();
    });
  }

  Future<void> _fetchFilteredMyEvents() async {
    Set<String> homeEventIds = Set.from(_userHomeEvents);
    DateTime now = DateTime.now();

    List<DocumentSnapshot> homeEventsDocs = [];
    for (var eventId in homeEventIds) {
      DocumentSnapshot eventSnapshot =
          await _firestore.collection('events').doc(eventId).get();
      if (eventSnapshot.exists && eventSnapshot['date'].toDate().isAfter(now)) {
        homeEventsDocs.add(eventSnapshot);
      }
    }

    QuerySnapshot allEventsSnapshot =
        await _firestore.collection('events').get();
    List<DocumentSnapshot> otherEventsDocs = allEventsSnapshot.docs
        .where((doc) =>
            !homeEventIds.contains(doc.id) && doc['date'].toDate().isAfter(now))
        .toList();

    List<DocumentSnapshot> combinedEvents = []
      ..addAll(homeEventsDocs)
      ..addAll(otherEventsDocs);

    List<DocumentSnapshot> filteredEvents = combinedEvents.where((doc) {
      var event = doc.data() as Map<String, dynamic>;
      DateTime eventDate = (event['date'] as Timestamp).toDate();

      if (_searchQuery.isNotEmpty &&
          !event['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_selectedCategory != 'None' &&
          event['category'] != _selectedCategory) {
        return false;
      }

      if (_selectedLocation != 'None' && event['city'] != _selectedLocation) {
        return false;
      }

      if (_selectedDate != null) {
        DateTime startDate = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        DateTime endDate = DateTime(_selectedDate!.year, _selectedDate!.month,
            _selectedDate!.day, 23, 59, 59);

        if (eventDate.isBefore(startDate) || eventDate.isAfter(endDate)) {
          return false;
        }
      }

      return eventDate.isAfter(now);
    }).toList();

    setState(() {
      _myEvents = filteredEvents;
    });
  }
}
