import 'package:eventsphere/pages/creator_home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:eventsphere/widgets/layout.dart';
import 'package:geocoding/geocoding.dart';
import 'package:eventsphere/pages/event_qrcode_screen.dart';
import 'package:dart_geohash/dart_geohash.dart';

class EventCreationPage extends StatefulWidget {
  const EventCreationPage({super.key});

  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _overviewController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCity;

  final List<String> _cities = [
    'Amsterdam',
    'Athens',
    'Berlin',
    'London',
    'Madrid',
    'Paris',
    'Patras',
    'Rome',
    'Seattle',
    'Sydney',
    'Thessaloniki',
    'Toronto'
  ];
  List<String> filteredCities = [];
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Art',
    'Education',
    'Entertainment',
    'Food',
    'Health',
    'Music',
    'Networking',
    'Outdoors',
    'Sports',
    'Technology'
  ];
  List<String> filteredCategories = [];
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isDisabledFriendly = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _headerController.dispose();
    _overviewController.dispose();
    _streetNameController.dispose();
    _priceController.dispose();
    _availabilityController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    filteredCategories = _categories;
    filteredCities = _cities;
  }

  void filterCategories(String query) {
    List<String> filtered;

    if (query.isEmpty) {
      filtered = [
        'None',
        ..._categories.where((category) => category != 'None')
      ];
    } else {
      filtered = _categories
          .where((category) =>
              category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (filtered.isEmpty) {
        filtered = ['None'];
      }
    }

    setState(() {
      filteredCategories = filtered;
    });
  }

  void filterLocations(String query) {
    List<String> filtered;

    if (query.isEmpty) {
      filtered = ['None', ..._cities.where((location) => location != 'None')];
    } else {
      filtered = _cities
          .where((location) =>
              location.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (filtered.isEmpty) {
        filtered = ['None'];
      }
    }

    setState(() {
      filteredCities = filtered;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _eventDate) {
      setState(() {
        _eventDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (pickedTime != null && pickedTime != _eventTime) {
      setState(() {
        _eventTime = pickedTime;
      });
    }
  }

  Future<Location> _getCoordinatesFromAddress(
      String streetName, String streetNumber, String city) async {
    String address = '$streetName $streetNumber, $city';
    List<Location> locations = await locationFromAddress(address);
    return locations.first;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => controller.clear(),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    String? value,
    void Function(String?)? onChanged,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: label),
          value: value,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCity == null || _selectedCity!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a city')),
        );
        return;
      }
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      try {
        DocumentReference eventRef = _firestore.collection('events').doc();

        String? creatorUsername;
        if (_user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(_user.uid)
              .get();
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;
          creatorUsername = userData?['username'];
        }

        Location location = await _getCoordinatesFromAddress(
            _streetNameController.text,
            _streetNumberController.text.isEmpty
                ? ''
                : _streetNumberController.text,
            _selectedCity ?? 'Athens');

        String creatorFirstLetter = '';
        if (creatorUsername != null && creatorUsername.isNotEmpty) {
          creatorFirstLetter = creatorUsername[0].toUpperCase();
        }

        if (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == 0.0) {
          _priceController.text = 'Free';
        } else {
          double? priceVal = double.tryParse(_priceController.text);
          if (priceVal != null) {
            _priceController.text = priceVal.toStringAsFixed(2);
          }
        }

        if (_streetNumberController.text.isEmpty ||
            int.tryParse(_streetNumberController.text) == 0) {
          _streetNumberController.text = 'No Street Number';
        } else {
          int? streetNumberVal = int.tryParse(_streetNumberController.text);
          if (streetNumberVal != null) {
            _streetNumberController.text = streetNumberVal.toString();
          }
        }

        String geohash =
            GeoHasher().encode(location.latitude, location.longitude);

        await eventRef.set({
          'eventID': eventRef.id,
          'title': _titleController.text,
          'header': _headerController.text,
          'overview': _overviewController.text,
          'description': _descriptionController.text,
          'city': _selectedCity,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'geohash': geohash,
          'streetName': _streetNameController.text,
          'streetNumber': _streetNumberController.text,
          'creatorFirstLetter': creatorFirstLetter,
          'category': _selectedCategory,
          'price': _priceController.text,
          'availability': int.parse(_availabilityController.text),
          'imageURL': _imageUrlController.text,
          'date': Timestamp.fromDate(DateTime(
            _eventDate.year,
            _eventDate.month,
            _eventDate.day,
            _eventTime.hour,
            _eventTime.minute,
          )),
          'isDisabledFriendly': _isDisabledFriendly,
          'creatorUid': _user?.uid,
        });

        if (_user != null) {
          DocumentReference userRef =
              _firestore.collection('Users').doc(_user.uid);
          await userRef.update({
            'publishedEvents': FieldValue.arrayUnion([eventRef.id])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => EventQRCodeScreen(eventId: eventRef.id)),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCity == null || _selectedCity!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a city')),
        );
        return;
      }
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      try {
        DocumentReference eventRef = _firestore.collection('savedEvents').doc();

        String? creatorUsername;
        if (_user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(_user.uid)
              .get();
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;
          creatorUsername = userData?['username'];
        }

        Location location = await _getCoordinatesFromAddress(
            _streetNameController.text,
            _streetNumberController.text.isEmpty
                ? ''
                : _streetNumberController.text,
            _selectedCity ?? 'Athens');

        String creatorFirstLetter = '';
        if (creatorUsername != null && creatorUsername.isNotEmpty) {
          creatorFirstLetter = creatorUsername[0].toUpperCase();
        }

        if (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == 0.0) {
          _priceController.text = 'Free';
        } else {
          double? priceVal = double.tryParse(_priceController.text);
          if (priceVal != null) {
            _priceController.text = priceVal.toStringAsFixed(2);
          }
        }

        if (_streetNumberController.text.isEmpty ||
            int.tryParse(_streetNumberController.text) == 0) {
          _streetNumberController.text = 'No Street Number';
        } else {
          int? streetNumberVal = int.tryParse(_streetNumberController.text);
          if (streetNumberVal != null) {
            _streetNumberController.text = streetNumberVal.toString();
          }
        }

        String geohash =
            GeoHasher().encode(location.latitude, location.longitude);

        await eventRef.set({
          'eventID': eventRef.id,
          'title': _titleController.text,
          'header': _headerController.text,
          'overview': _overviewController.text,
          'description': _descriptionController.text,
          'city': _selectedCity,
          'streetName': _streetNameController.text,
          'streetNumber': _streetNumberController.text,
          'creatorFirstLetter': creatorFirstLetter,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'geohash': geohash,
          'category': _selectedCategory,
          'price': _priceController.text,
          'availability': int.parse(_availabilityController.text),
          'imageURL': _imageUrlController.text,
          'date': Timestamp.fromDate(DateTime(
            _eventDate.year,
            _eventDate.month,
            _eventDate.day,
            _eventTime.hour,
            _eventTime.minute,
          )),
          'isDisabledFriendly': _isDisabledFriendly,
          'creatorUid': _user?.uid,
        });

        if (_user != null) {
          DocumentReference userRef =
              _firestore.collection('Users').doc(_user.uid);
          await userRef.update({
            'savedEvents': FieldValue.arrayUnion([eventRef.id])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved successfully!')),
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CreatorHomePage(),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      mode: PageMode.creatorMode,
      showBackButton: true,
      showCameraIcon: true,
      showProfileIcon: true,
      bodyContent: _buildEventCreationContent(),
    );
  }

  Widget _buildEventCreationContent() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter event title' : null,
              ),
              _buildTextField(
                controller: _headerController,
                label: 'Header',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter event header' : null,
              ),
              _buildTextField(
                controller: _overviewController,
                label: 'Overview',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter event overview' : null,
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter event description' : null,
              ),
              _buildDropdownField(
                label: 'City',
                items: _cities,
                value: _selectedCity,
                onTap: () => _showLocationDialog(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
              ),
              _buildTextField(
                controller: _streetNameController,
                label: 'Street Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter street name' : null,
              ),
              _buildTextField(
                controller: _streetNumberController,
                label: 'Street Number',
                validator: (value) {
                  if (value == null) {
                    return 'Please enter a valid number or no number';
                  }
                  if (value.isEmpty) return null;
                  if (value != 'No Street Number' &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number or no number';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              _buildDropdownField(
                label: 'Category',
                items: _categories,
                value: _selectedCategory,
                onTap: () => _showCategoryDialog(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              _buildTextField(
                controller: _priceController,
                label: 'Price',
                validator: (value) {
                  if (value == null) {
                    return 'Please enter a valid number or no number';
                  }
                  if (value.isEmpty) return null;
                  if (value != 'Free' && double.tryParse(value) == null) {
                    return 'Please enter a valid number or no number';
                  }
                  return null;
                },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL',
                validator: (value) {
                  //if (value!.isEmpty) return 'Please enter image URL';
                  return null;
                },
              ),
              _buildTextField(
                controller: _availabilityController,
                label: 'Availability',
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter ticket availability';
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Event Date:', style: TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(DateFormat('yyyy-MM-dd').format(_eventDate),
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Event Time:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeButton(
                            label: 'Hour',
                            value: _eventTime.hour.toString().padLeft(2, '0'),
                            onTap: () => _selectTime(context),
                          ),
                          const Text(':',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          _buildTimeButton(
                            label: 'Minute',
                            value: _eventTime.minute.toString().padLeft(2, '0'),
                            onTap: () => _selectTime(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Disabled Friendly:',
                      style: TextStyle(fontSize: 16)),
                  Switch(
                    value: _isDisabledFriendly,
                    onChanged: (bool value) {
                      setState(() {
                        _isDisabledFriendly = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    _buildFixedButton('Submit', _submitEvent),
                    _buildFixedButton('Save', _saveEvent),
                    _buildFixedButton('Cancel', () {
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue[800],
        backgroundColor: Colors.grey[50],
        fixedSize: const Size(100, 40),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      child: Text(label),
    );
  }

  Widget _buildTimeButton(
      {required String label,
      required String value,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Category'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _categoryController,
                      onChanged: (value) {
                        setState(() {
                          filterCategories(value);
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type to filter categories',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredCategories[index]),
                            onTap: () {
                              this.setState(() {
                                _selectedCategory = filteredCategories[index];
                                Navigator.of(context).pop();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Location'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _cityController,
                      onChanged: (value) {
                        setState(() {
                          filterLocations(value);
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type to filter location',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredCities[index]),
                            onTap: () {
                              this.setState(() {
                                _selectedCity = filteredCities[index];
                                Navigator.of(context).pop();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[50],
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${label.split(':')[0]}:',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                label.split(':')[1].trim(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
