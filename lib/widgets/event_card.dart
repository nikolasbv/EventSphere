import 'package:eventsphere/pages/user_tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:eventsphere/pages/user_event_details.dart';
import 'package:eventsphere/pages/creator_event_details.dart';
import 'package:eventsphere/pages/creator_event_edit_published.dart';
import 'package:eventsphere/pages/creator_event_edit_saved.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventsphere/pages/user_event_booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

enum EventCardType {
  book,
  tickets,
  published,
  saved,
}

class EventCardVariant {
  final bool showThumbUp;
  final bool showThumbDown;
  final bool showBookmark;
  final bool showButton1;
  final bool showButton2;
  final bool showButton3;
  final String button1Label;
  final String button2Label;
  final String button3Label;

  EventCardVariant({
    this.showThumbUp = false,
    this.showThumbDown = false,
    this.showBookmark = false,
    this.showButton1 = false,
    this.showButton2 = false,
    this.showButton3 = false,
    this.button1Label = '',
    this.button2Label = '',
    this.button3Label = '',
  });
}

Map<EventCardType, EventCardVariant> cardVariants = {
  EventCardType.book: EventCardVariant(
    showThumbUp: true,
    showThumbDown: true,
    showBookmark: true,
    showButton1: true,
    button1Label: 'Book',
  ),
  EventCardType.tickets: EventCardVariant(
    showThumbUp: true,
    showThumbDown: true,
    showBookmark: true,
    showButton1: true,
    button1Label: 'Tickets',
  ),
  EventCardType.published: EventCardVariant(
    showButton1: true,
    showButton2: true,
    showButton3: true,
    button1Label: 'Edit',
    button2Label: 'Remove',
    button3Label: 'Preview',
  ),
  EventCardType.saved: EventCardVariant(
    showButton1: true,
    showButton2: true,
    showButton3: true,
    button1Label: 'Edit',
    button2Label: 'Delete',
    button3Label: 'Preview',
  ),
};

class SmallEventCard extends StatelessWidget {
  final String eventId;
  final String imageUrl;
  final String eventTime;
  final String eventDate;
  final String eventLocation;
  final String eventTitle;
  final String avatarText;

  const SmallEventCard({
    super.key,
    required this.eventId,
    required this.imageUrl,
    required this.eventTime,
    required this.eventDate,
    required this.eventLocation,
    required this.eventTitle,
    required this.avatarText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Card(
        elevation: 2.0,
        margin: const EdgeInsets.all(2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue[800],
                  child: Text(
                    avatarText,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        eventTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Time: $eventTime   Date: $eventDate',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center),
                    Text('Location: $eventLocation',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: Text(
                          'Image not available',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final String eventId;
  final String imageUrl;
  final String eventTime;
  final String eventDate;
  final String eventTitle;
  final String eventHeader;
  final String eventLocation;
  final String eventDescription;
  final String eventCost;
  final String avatarText;
  final EventCardType cardType;
  final int availableTickets;
  final bool initialThumbUpSelected;
  final bool initialThumbDownSelected;
  final bool initialBookmarkSelected;
  final VoidCallback? onTap;
  final bool isNavigationEnabled;
  final bool initialLikeState;
  final bool initialBookmarkState;
  final bool initialDislikeState;
  final bool isPreview;
  final VoidCallback? onLikePressed;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onDislikePressed;
  final VoidCallback? onEditPressed;

  const EventCard({
    super.key,
    required this.eventId,
    required this.imageUrl,
    required this.eventTime,
    required this.eventDate,
    required this.eventTitle,
    required this.eventHeader,
    required this.eventLocation,
    required this.eventDescription,
    required this.eventCost,
    required this.avatarText,
    required this.cardType,
    required this.availableTickets,
    this.initialThumbUpSelected = false,
    this.initialThumbDownSelected = false,
    this.initialBookmarkSelected = false,
    this.initialLikeState = false,
    this.initialBookmarkState = false,
    this.initialDislikeState = false,
    this.isPreview = false,
    this.onTap,
    this.onLikePressed,
    this.onDislikePressed,
    this.onBookmarkPressed,
    this.isNavigationEnabled = true,
    this.onEditPressed,
  });

  @override
  _EventCardState createState() => _EventCardState();

  static Widget createDummy({
    EventCardType cardType = EventCardType.book,
    bool bookmarked = false,
    bool eventDetailsEnabled = true,
  }) {
    return EventCard(
      eventId: '123',
      imageUrl: 'https://picsum.photos/536/354',
      eventTime: '18:00',
      eventDate: '18/11/23',
      eventTitle: 'Athens Hoops Showdown',
      eventHeader: 'Basketball Game at Olympian Courts',
      eventLocation: 'Olympian Courts, Athens',
      eventDescription:
          'An exciting basketball game featuring local Athens teams competing under the gaze of the Acropolis.',
      eventCost: '17.00',
      avatarText: 'E',
      cardType: cardType,
      initialThumbUpSelected: false,
      initialThumbDownSelected: false,
      initialBookmarkSelected: bookmarked,
      isNavigationEnabled: eventDetailsEnabled,
      availableTickets: 1000,
    );
  }
}
//

class _EventCardState extends State<EventCard> {
  late bool isThumbUpSelected = false;
  late bool isThumbDownSelected = false;
  late bool isBookmarkSelected = false;
  late bool isDisliked = false;

  @override
  void initState() {
    super.initState();
    isThumbUpSelected = widget.initialLikeState;
    isThumbDownSelected = widget.initialThumbDownSelected;
    isBookmarkSelected = widget.initialBookmarkState;
    isDisliked = widget.initialDislikeState;
  }

  void navigateToEventDetails() {
    if (widget.isNavigationEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserEventDetails(
            eventId: widget.eventId,
            cardType: widget.cardType,
          ),
        ),
      ).then((value) {
        if (value == true) {
          _fetchEventData();
        }
      });
    }
  }

  void _fetchEventData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          Set<String> likedEvents = Set.from(userData['likedEvents'] ?? []);
          Set<String> dislikedEvents =
              Set.from(userData['dislikedEvents'] ?? []);
          Set<String> bookmarkedEvents =
              Set.from(userData['bookmarkedEvents'] ?? []);

          setState(() {
            isThumbUpSelected = likedEvents.contains(widget.eventId);
            isThumbDownSelected = dislikedEvents.contains(widget.eventId);
            isBookmarkSelected = bookmarkedEvents.contains(widget.eventId);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching user event data: $e'),
          ),
        );
      }
    }
  }

  Future<void> launchGoogleMaps(
      String city, String streetName, String streetNumber) async {
    String query = Uri.encodeComponent('$streetName $streetNumber $city');
    final Uri googleMapsUri = Uri.parse("geo:0,0?q=$query");

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch Google Maps for $query');
    }
  }

  void _navigateToMaps() async {
    DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    if (eventSnapshot.exists) {
      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;
      String city = eventData['city'];
      String streetName = eventData['streetName'];
      String streetNumber = eventData['streetNumber'].toString();
      await launchGoogleMaps(city, streetName, streetNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event location details not found.')),
      );
    }
  }

  void showConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: Text('Are you sure you want to $action this event?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleRemovePublishedEvent() async {
    showConfirmationDialog('remove', () async {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .delete();

        if (widget.cardType == EventCardType.published) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            DocumentReference userRef =
                FirebaseFirestore.instance.collection('Users').doc(user.uid);
            await userRef.update({
              'publishedEvents': FieldValue.arrayRemove([widget.eventId])
            });
          }

          var allUsersSnapshot =
              await FirebaseFirestore.instance.collection('Users').get();
          for (var doc in allUsersSnapshot.docs) {
            await doc.reference.update({
              'bookmarkedEvents': FieldValue.arrayRemove([widget.eventId]),
              'dislikedEvents': FieldValue.arrayRemove([widget.eventId]),
              'homeEvents': FieldValue.arrayRemove([widget.eventId]),
              'likedEvents': FieldValue.arrayRemove([widget.eventId]),
              'myEvents': FieldValue.arrayRemove([widget.eventId]),
              'savedEvents': FieldValue.arrayRemove([widget.eventId]),
            });
          }

          var ticketsSnapshot = await FirebaseFirestore.instance
              .collection('tickets')
              .where('eventId', isEqualTo: widget.eventId)
              .get();

          for (var doc in ticketsSnapshot.docs) {
            await doc.reference.delete();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Event and related tickets removed successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error removing event and related tickets: $e')),
        );
      }
    });
  }

  void handleDeleteSavedEvent() async {
    showConfirmationDialog('delete', () async {
      try {
        await FirebaseFirestore.instance
            .collection('savedEvents')
            .doc(widget.eventId)
            .delete();

        if (widget.cardType == EventCardType.saved) {
          User? user = FirebaseAuth.instance.currentUser;
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('Users').doc(user!.uid);
          await userRef.update({
            'savedEvents': FieldValue.arrayRemove([widget.eventId])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final variant = cardVariants[widget.cardType]!;

    return InkWell(
      onTap: widget.isNavigationEnabled ? navigateToEventDetails : null,
      child: SizedBox(
        child: Card(
          elevation: 2.0,
          margin: const EdgeInsets.all(12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                title: Text(
                  widget.eventHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    'Time: ${widget.eventTime}   Date: ${widget.eventDate}'),
                trailing: CircleAvatar(
                  backgroundColor: Colors.blue[800],
                  child: Text(widget.avatarText,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
              Image.network(
                widget.imageUrl,
                width: double.infinity,
                height: 160.0,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 160.0,
                    alignment: Alignment.center,
                    child: Text(
                      'Image not available',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Text(
                  widget.eventTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.eventLocation,
                        style: const TextStyle(fontSize: 16.0),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: widget.isPreview ? null : _navigateToMaps,
                      child: Icon(
                        Icons.location_on,
                        size: 20.0,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.eventDescription,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Cost: ${widget.eventCost == "Free" ? "Free" : "${widget.eventCost} Euros"}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ButtonBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (variant.showThumbUp)
                        IconButton(
                          icon: Icon(isThumbUpSelected
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined),
                          color: isThumbUpSelected
                              ? Colors.blue[800]
                              : Colors.grey,
                          onPressed: () {
                            if (!isThumbDownSelected &&
                                widget.onLikePressed != null) {
                              widget.onLikePressed!();
                              setState(() {
                                isThumbUpSelected = !isThumbUpSelected;
                              });
                            }
                          },
                        ),
                      if (variant.showThumbDown)
                        IconButton(
                          icon: Icon(isThumbDownSelected
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined),
                          color: isThumbDownSelected
                              ? Colors.blue[800]
                              : Colors.grey,
                          onPressed: () {
                            if (!isThumbUpSelected &&
                                widget.onDislikePressed != null) {
                              widget.onDislikePressed!();
                              setState(() {
                                isThumbDownSelected = !isThumbDownSelected;
                              });
                            }
                          },
                        ),
                      if (variant.showBookmark)
                        IconButton(
                          icon: Icon(isBookmarkSelected
                              ? Icons.bookmark
                              : Icons.bookmark_outline),
                          color: isBookmarkSelected
                              ? Colors.blue[800]
                              : Colors.grey,
                          onPressed: () {
                            if (widget.onBookmarkPressed != null) {
                              widget.onBookmarkPressed!();
                              setState(() {
                                isBookmarkSelected = !isBookmarkSelected;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (variant.showButton3)
                        _buildButton(variant.button3Label, Colors.grey[50]!,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatorEventDetails(
                                  eventId: widget.eventId,
                                  cardType: widget.cardType),
                            ),
                          );
                        },
                            textColor: Colors.blue[800],
                            borderColor: Colors.blue[800]),
                      if (variant.showButton1 && variant.showButton3)
                        const SizedBox(width: 4),
                      if (variant.showButton2 &&
                          widget.cardType == EventCardType.published)
                        _buildButton(variant.button2Label, Colors.red,
                            handleRemovePublishedEvent),
                      if (variant.showButton2 &&
                          widget.cardType == EventCardType.saved)
                        _buildButton(variant.button2Label, Colors.red,
                            handleDeleteSavedEvent),
                      if (variant.showButton3 && variant.showButton2)
                        const SizedBox(width: 4),
                      if (variant.showButton1 &&
                          widget.cardType == EventCardType.published)
                        _buildButton(variant.button1Label,
                            Colors.blue[800] ?? Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventEditPublishedPage(
                                  eventId: widget.eventId,
                                  cardType: widget.cardType),
                            ),
                          );
                        }),
                      if (variant.showButton1 &&
                          widget.cardType == EventCardType.saved)
                        _buildButton(variant.button1Label,
                            Colors.blue[800] ?? Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventEditSavedPage(
                                  eventId: widget.eventId,
                                  cardType: widget.cardType),
                            ),
                          );
                        }),
                      if (variant.showButton1 &&
                          widget.cardType == EventCardType.book &&
                          widget.isPreview == false)
                        _buildButton(
                          variant.button1Label,
                          Colors.blue[800] ?? Colors.blue,
                          () => _handleButtonPress(
                              context,
                              widget.availableTickets,
                              widget.eventId,
                              widget.eventDate,
                              widget.eventTime),
                        ),
                      if (variant.showButton1 &&
                          widget.cardType == EventCardType.tickets)
                        _buildButton(variant.button1Label,
                            Colors.blue[800] ?? Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserTicketsPage(
                                eventId: widget.eventId,
                              ),
                            ),
                          );
                        }),
                      if (variant.showButton1 &&
                          widget.cardType == EventCardType.book &&
                          widget.isPreview == true)
                        _buildButton(variant.button1Label,
                            Colors.blue[800] ?? Colors.blue, () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleButtonPress(BuildContext context, int availableTickets,
      String eventId, String eventDateString, String eventTimeString) {
    DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
    DateTime eventDateTime =
        dateFormat.parse('$eventDateString $eventTimeString');

    DateTime now = DateTime.now();

    if (eventDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This event is past its date.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (availableTickets > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingPage(eventId: eventId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tickets available for this event.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildButton(
      String label, Color backgroundColor, VoidCallback onPressed,
      {Color? textColor, Color? borderColor}) {
    return SizedBox(
      width: 93,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? Colors.white,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        child: Text(label,
            style: TextStyle(color: textColor ?? Colors.white),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class DummyEventCard extends StatelessWidget {
  final EventCardType cardType;

  const DummyEventCard({super.key, this.cardType = EventCardType.book});

  @override
  Widget build(BuildContext context) {
    return EventCard.createDummy(cardType: cardType);
  }
}
