import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/event_card.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:eventsphere/widgets/search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatorSavedEvents extends StatefulWidget {
  const CreatorSavedEvents({super.key});

  @override
  _CreatorSavedEventsState createState() => _CreatorSavedEventsState();
}

class _CreatorSavedEventsState extends State<CreatorSavedEvents> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allEvents = [];
  Stream<List<String>>? _eventIdsStream;
  String _searchQuery = '';
  String _selectedCategory = 'None';
  String _selectedLocation = 'None';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _setupEventIdsStream();
  }

  void _setupEventIdsStream() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _eventIdsStream = _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .snapshots()
          .map((snapshot) =>
              List<String>.from(snapshot.data()?['savedEvents'] ?? []));
    }
  }

  Future<void> _fetchEventsData(List<String> eventIds) async {
    List<Map<String, dynamic>> eventsData = [];
    for (String id in eventIds) {
      var docSnapshot =
          await _firestore.collection('savedEvents').doc(id).get();
      if (docSnapshot.exists) {
        eventsData.add(docSnapshot.data() as Map<String, dynamic>);
      }
    }
    setState(() {
      _allEvents = eventsData;
    });
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    return _allEvents.where((event) {
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
        DateTime eventDate = (event['date'] as Timestamp).toDate();
        DateTime startDate = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        DateTime endDate = DateTime(_selectedDate!.year, _selectedDate!.month,
            _selectedDate!.day, 23, 59, 59);

        if (eventDate.isBefore(startDate) || eventDate.isAfter(endDate)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: false,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.creatorMode,
      activeNavItem: NavItem.savedEvents,
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
              child: _eventIdsStream == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<String>>(
                      stream: _eventIdsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        _fetchEventsData(snapshot.data!);

                        var filteredEvents = _getFilteredEvents();
                        return ListView.builder(
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            var event = filteredEvents[index];
                            DateTime eventDateTime =
                                (event['date'] as Timestamp).toDate();
                            String formattedDate =
                                DateFormat('dd/MM/yy').format(eventDateTime);
                            String formattedTime =
                                DateFormat('HH:mm').format(eventDateTime);
                            String streetName = event['streetName'] ?? '';
                            String streetNumber =
                                event['streetNumber']?.toString().trim() ?? '';
                            String city = event['city'] ?? '';

                            String location = streetName;
                            if (streetNumber.isNotEmpty &&
                                streetNumber != 'No Street Number' &&
                                streetNumber != '0') {
                              location += ' $streetNumber';
                            }
                            location += ', $city';

                            String eventId = event['eventID'] ?? '';

                            return EventCard(
                              eventId: eventId,
                              imageUrl: event['imageURL'] ??
                                  'https://picsum.photos/536/354',
                              eventTime: formattedTime,
                              eventDate: formattedDate,
                              eventTitle: event['title'] ?? 'No title',
                              eventHeader: event['header'] ?? 'No header',
                              eventLocation: location,
                              eventDescription:
                                  event['overview'] ?? 'No description',
                              eventCost: event['price']?.toString() ?? 'Free',
                              avatarText: event['creatorFirstLetter'] ?? '',
                              cardType: EventCardType.saved,
                              availableTickets: event['availability'] ?? 0,
                              isNavigationEnabled: false,
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
}
