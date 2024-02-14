import 'package:flutter/material.dart';
import 'package:eventsphere/pages/creator_home_page.dart';
import 'package:eventsphere/pages/user_home_page.dart';
import 'package:eventsphere/pages/creator_my_events.dart';
import 'package:eventsphere/pages/user_discover_page.dart';
import 'package:eventsphere/pages/creator_saved_events.dart';
import 'package:eventsphere/pages/user_my_events.dart';
import 'package:eventsphere/pages/user_profile_page.dart';
import 'package:eventsphere/pages/creator_profile_page.dart';
import 'package:eventsphere/pages/qr_scanner_page.dart';
import 'package:geolocator/geolocator.dart';

enum PageMode {
  creatorMode,
  userMode,
}

enum NavItem {
  none,
  home,
  discover,
  myEvents,
  savedEvents,
}

class PageTemplate extends StatelessWidget {
  final Widget? bodyContent;
  final bool showBackButton;
  final bool showCameraIcon;
  final bool showProfileIcon;
  final bool isDetails;
  final PageMode mode;
  final NavItem activeNavItem;

  const PageTemplate({
    super.key,
    this.bodyContent,
    this.showBackButton = false,
    this.showCameraIcon = true,
    this.showProfileIcon = true,
    this.isDetails = false,
    this.mode = PageMode.userMode,
    this.activeNavItem = NavItem.none,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (isDetails) {
                    Navigator.pop(context, true);
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              )
            : null,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 50),
            const SizedBox(width: 8),
            const Text(
              'EventSphere',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          if (showCameraIcon)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerPage()),
                );
              },
            ),
          if (showProfileIcon)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                if (mode == PageMode.userMode) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserProfileScreen()),
                  );
                } else if (mode == PageMode.creatorMode) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreatorProfileScreen()),
                  );
                }
              },
            ),
        ],
        backgroundColor: Colors.grey[50],
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: bodyContent ?? const SizedBox.shrink(),
      bottomNavigationBar: _buildBottomNavigationBar(mode, context),
    );
  }

  BottomAppBar _buildBottomNavigationBar(PageMode mode, BuildContext context) {
    switch (mode) {
      case PageMode.creatorMode:
        return _buildCreatorModeNavBar(context);
      case PageMode.userMode:
        return _buildUserModeNavBar(context);
      default:
        return _buildCreatorModeNavBar(context);
    }
  }

  BottomAppBar _buildCreatorModeNavBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomAppBarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => _navigateTo(context, const CreatorHomePage()),
            item: NavItem.home,
          ),
          _buildBottomAppBarItem(
            icon: Icons.event,
            label: 'My Events',
            onTap: () => _navigateTo(context, const CreatorMyEvents()),
            item: NavItem.myEvents,
          ),
          _buildBottomAppBarItem(
            icon: Icons.bookmark_border,
            label: 'Saved Events',
            onTap: () => _navigateTo(context, const CreatorSavedEvents()),
            item: NavItem.savedEvents,
          ),
        ],
      ),
    );
  }

  BottomAppBar _buildUserModeNavBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomAppBarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => _navigateTo(context, const UserHomePage()),
            item: NavItem.home,
          ),
          _buildBottomAppBarItem(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: () => _navigateTo(context, const DiscoverPage()),
            item: NavItem.discover,
          ),
          _buildBottomAppBarItem(
            icon: Icons.event,
            label: 'My Events',
            onTap: () => _navigateTo(context, const UserMyEvents()),
            item: NavItem.myEvents,
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    if (page is DiscoverPage) {
      _checkLocationServiceAndNavigate(context, page);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  Future<void> _checkLocationServiceAndNavigate(
      BuildContext context, Widget page) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enable location services to use the Discover feature.')),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    print('Initial Permission: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please give location permissions to use the Discover feature.')),
        );
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildBottomAppBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required NavItem item,
  }) {
    final bool isActive =
        activeNavItem != NavItem.none && item == activeNavItem;
    final color = isActive ? Colors.blue[800] : Colors.black87;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
