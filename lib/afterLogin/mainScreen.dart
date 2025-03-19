
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scooter/afterLogin/myDrawer.dart';
import 'package:scooter/afterLogin/scooterMap.dart';
import 'package:scooter/provider/user_provider.dart';

class MainScreen extends StatefulWidget {
  final String nameSurname;
  final String email;

  MainScreen({required this.nameSurname, required this.email});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScooterMap _scooterMap;
  late Widget _currentPage;

  @override
  void initState() {
    super.initState();
    // Create a single instance of ScooterMap
    _scooterMap = ScooterMap(key: GlobalKey());
    _currentPage = _scooterMap;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserData(widget.email);
    });
  }

  void _onPageSelected(Widget page) {
    setState(() {
      // If returning to map view, use the existing instance
      if (page.runtimeType == ScooterMap) {
        _currentPage = _scooterMap;
      } else {
        _currentPage = page;
      }
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userProvider.userData == null) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }

        return SafeArea(
          child: Scaffold(
            key: _scaffoldKey,
            drawer: MyDrawer(
              onPageChange: _onPageSelected,
              currentPage: _currentPage,
            ),
            drawerEnableOpenDragGesture: false,
            body: Stack(
              children: [
                // Use IndexedStack to maintain state of all pages
                IndexedStack(
                  index: _currentPage == _scooterMap ? 0 : 1,
                  children: [
                    _scooterMap,
                    if (_currentPage != _scooterMap) _currentPage,
                  ],
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}