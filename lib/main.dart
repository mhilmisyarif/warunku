import 'package:flutter/material.dart';
import 'package:warunku/screens/home_screen.dart';
import 'package:warunku/screens/buy_screen.dart';
import 'package:warunku/screens/stats_screen.dart';
// import 'package:warunku/screens/detail_item_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warunku',
      theme: ThemeData(
        fontFamily: "Inter",
        primaryColor: const Color(0xFF102C57),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: DetailItemScreen(),
      home: Scaffold(
        bottomNavigationBar: NavigationBar(
          indicatorColor: const Color(0xFFF8F0E5),
          height: 55,
          animationDuration: const Duration(seconds: 1),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          backgroundColor: const Color(0xFFF8F0E5),
          destinations: const [
            NavigationDestination(
              selectedIcon: Icon(
                Icons.home,
                color: Color(0xFF102C57),
                size: 32,
              ),
              icon: Icon(
                Icons.home_outlined,
                color: Color(0xFF102C57),
                size: 32,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.shopping_cart,
                color: Color(0xFF102C57),
                size: 32,
              ),
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF102C57),
                size: 32,
              ),
              label: 'Buy',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.analytics,
                color: Color(0xFF102C57),
                size: 32,
              ),
              icon: Icon(
                Icons.analytics_outlined,
                color: Color(0xFF102C57),
                size: 32,
              ),
              label: 'Stats',
            ),
          ],
        ),
        body: IndexedStack(
          index: currentPageIndex,
          children: const [
            HomeScreen(),
            BuyScreen(),
            StatsScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF102C57),
          child: const Icon(Icons.search, color: Color(0xFFF8F0E5)),
        ),
      ),
    );
  }
}
