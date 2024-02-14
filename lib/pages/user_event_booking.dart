import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:eventsphere/pages/user_my_events.dart';

class BookingPage extends StatefulWidget {
  final String eventId;

  const BookingPage({super.key, required this.eventId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardCVVController = TextEditingController();
  final TextEditingController cardNameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ticketCountController =
      TextEditingController(text: '1');
  final TextEditingController totalCostController = TextEditingController();

  Map<String, dynamic>? _eventDetails;
  String _pricePerTicket = '0.0';
  bool _isPayButtonEnabled = false;
  int _availableTickets = 0;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
    _setupListeners();
  }

  void _setupListeners() {
    List<TextEditingController> controllers = [
      cardNumberController,
      cardExpiryController,
      cardCVVController,
      cardNameController,
      fullNameController
    ];

    for (var controller in controllers) {
      controller.addListener(() {
        setState(() {
          _isPayButtonEnabled = _arePaymentFieldsFilled;
        });
      });
    }
  }

  Future<void> _fetchEventDetails() async {
    try {
      DocumentSnapshot eventSnapshot =
          await _firestore.collection('events').doc(widget.eventId).get();
      if (eventSnapshot.exists) {
        setState(() {
          _eventDetails = eventSnapshot.data() as Map<String, dynamic>?;
          _pricePerTicket = _eventDetails?['price'].toString() ?? '0.0';
          _availableTickets = _eventDetails?['availability'] ?? 0;
          _updateTotalCost();
        });
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  void _updateTotalCost() {
    int ticketCount = int.tryParse(ticketCountController.text) ?? 1;
    if (_pricePerTicket.toLowerCase() == 'free') {
      totalCostController.text = 'Free';
    } else {
      double price = double.tryParse(_pricePerTicket) ?? 0.0;
      double totalCost = ticketCount * price;
      totalCostController.text = totalCost.toStringAsFixed(2);
    }
  }

  void _incrementTicketCount() {
    int currentCount = int.tryParse(ticketCountController.text) ?? 1;
    if (currentCount < _availableTickets) {
      ticketCountController.text = (currentCount + 1).toString();
      _updateTotalCost();
    } else {
      _showSnackBar("You cannot book more tickets than the available limit.");
    }
  }

  void _decrementTicketCount() {
    int currentCount = int.tryParse(ticketCountController.text) ?? 1;
    if (currentCount > 1) {
      ticketCountController.text = (currentCount - 1).toString();
      _updateTotalCost();
    }
  }

  bool get _arePaymentFieldsFilled {
    return cardNumberController.text.isNotEmpty &&
        cardExpiryController.text.isNotEmpty &&
        cardCVVController.text.isNotEmpty &&
        cardNameController.text.isNotEmpty &&
        fullNameController.text.isNotEmpty;
  }

  Future<void> _handleBooking() async {
    if (!_arePaymentFieldsFilled) {
      _showSnackBar("Please fill out all the payment details.");
      return;
    }

    int ticketCount = int.tryParse(ticketCountController.text) ?? 1;
    if (ticketCount > _availableTickets) {
      _showSnackBar("The number of tickets exceeds the available limit.");
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          _firestore.collection('Users').doc(user.uid);
      DocumentReference eventDocRef =
          _firestore.collection('events').doc(widget.eventId);

      try {
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot eventSnapshot = await transaction.get(eventDocRef);

          if (eventSnapshot.exists) {
            int currentAvailability = eventSnapshot['availability'];
            if (ticketCount <= currentAvailability) {
              transaction.update(eventDocRef,
                  {'availability': FieldValue.increment(-ticketCount)});

              await userDocRef.update({
                'myEvents': FieldValue.arrayUnion([widget.eventId])
              });

              await _firestore.collection('tickets').add({
                'eventId': widget.eventId,
                'userId': user.uid,
                'totalTickets': ticketCount,
                'totalCost': double.tryParse(totalCostController.text) ?? 0.0,
                'fullName': fullNameController.text,
                'bookingDate': Timestamp.now(),
                'isValidated': false,
              });

              _showSnackBar("Booking successful!");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserMyEvents(),
                ),
              );
            } else {
              _showSnackBar(
                  "The number of tickets exceeds the available limit.");
            }
          }
        });
      } catch (e) {
        _showSnackBar("Error during booking: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      showBackButton: true,
      showCameraIcon: false,
      showProfileIcon: true,
      mode: PageMode.userMode,
      activeNavItem: NavItem.none,
      bodyContent: _eventDetails == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('Booking Info',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _eventDetails?['title'],
                      readOnly: true,
                      decoration:
                          const InputDecoration(labelText: 'Event Title'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ticketCountController,
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: 'Total Tickets'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _decrementTicketCount,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _incrementTicketCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: totalCostController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(labelText: 'Total Cost'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                          labelText: 'Full Name (for booking)'),
                    ),
                    const SizedBox(height: 50),
                    Text('Payment Info',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cardNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Card Number'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cardExpiryController,
                      decoration: const InputDecoration(
                          labelText: 'Card Expiring Date'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cardCVVController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cardNameController,
                      decoration: const InputDecoration(labelText: 'Card Name'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isPayButtonEnabled ? _handleBooking : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue[800],
                        backgroundColor: Colors.grey[50],
                        fixedSize: const Size(140, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      child: const Text('Pay'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCVVController.dispose();
    cardNameController.dispose();
    fullNameController.dispose();
    ticketCountController.dispose();
    totalCostController.dispose();
    super.dispose();
  }
}
