import 'package:flutter/material.dart';

class SearchBarWithFilters extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String) onCategoryChanged;
  final Function(String) onLocationChanged;
  final Function(DateTime?) onDateChanged;

  const SearchBarWithFilters({
    super.key,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onDateChanged,
  });

  @override
  _SearchBarWithFiltersState createState() => _SearchBarWithFiltersState();
}

class _SearchBarWithFiltersState extends State<SearchBarWithFilters> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  String selectedCategory = 'None';

  final List<String> categories = [
    'Art',
    'Education',
    'Entertainment',
    'Food',
    'Health',
    'Music',
    'Networking',
    'Outdoors',
    'Sports',
    'Technology',
    'None'
  ];
  final TextEditingController categoryController = TextEditingController();
  List<String> filteredCategories = [];

  String selectedLocation = 'None';

  final List<String> locations = [
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
    'Toronto',
    'None'
  ];

  final TextEditingController locationController = TextEditingController();
  List<String> filteredLocations = [];

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    filteredCategories = categories;
    filteredLocations = locations;
  }

  void handleSearch(String query) {
    widget.onSearchChanged(query);
  }

  void _handleCategoryChange(String category) {
    print("Category Changed: $category");
    widget.onCategoryChanged(category);
  }

  void _handleLocationChange(String location) {
    widget.onLocationChanged(location);
  }

  void _handleDateChange(DateTime? date) {
    widget.onDateChanged(date);
  }

  void filterCategories(String query) {
    List<String> filtered;

    if (query.isEmpty) {
      filtered = [
        'None',
        ...categories.where((category) => category != 'None')
      ];
    } else {
      filtered = categories
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
      filtered = ['None', ...locations.where((location) => location != 'None')];
    } else {
      filtered = locations
          .where((location) =>
              location.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (filtered.isEmpty) {
        filtered = ['None'];
      }
    }

    setState(() {
      filteredLocations = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    double boxWidth = MediaQuery.of(context).size.width / 3 - 16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            borderRadius: BorderRadius.circular(30),
            elevation: 2,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search events',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => handleSearch(searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: handleSearch,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: boxWidth,
                child: _buildFilterChip(
                  label: 'Category: $selectedCategory',
                  isSelected: selectedCategory != 'None',
                  onTap: _showCategoryDialog,
                ),
              ),
              SizedBox(
                width: boxWidth,
                child: _buildFilterChip(
                  label: 'Location: $selectedLocation',
                  isSelected: selectedLocation != 'None',
                  onTap: _showLocationDialog,
                ),
              ),
              SizedBox(
                width: boxWidth,
                child: _buildFilterChip(
                  label:
                      'Date: ${selectedDate?.toLocal().toString().split(' ')[0] ?? 'None'}',
                  isSelected: selectedDate != null,
                  onTap: () => _selectDate(context),
                ),
              ),
            ],
          ),
        ),
      ],
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
                      controller: categoryController,
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
                                selectedCategory = filteredCategories[index];
                              });
                              _handleCategoryChange(selectedCategory);
                              Navigator.of(context).pop();
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
                      controller: locationController,
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
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredLocations[index]),
                            onTap: () {
                              this.setState(() {
                                selectedLocation = filteredLocations[index];
                              });
                              _handleLocationChange(selectedLocation);
                              Navigator.of(context).pop();
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

  Future<void> _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('None'),
                onTap: () {
                  setState(() {
                    selectedDate = null;
                    _handleDateChange(null);
                    Navigator.of(context).pop();
                  });
                },
              ),
              ListTile(
                title: const Text('Choose a Date'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2026),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      _handleDateChange(picked);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    categoryController.dispose();
    locationController.dispose();
    super.dispose();
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
