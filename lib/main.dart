// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:warunku/blocs/products/product_event.dart';

// Import BLoCs
import 'blocs/products/product_bloc.dart';
import 'blocs/customer/customer_bloc.dart';
import 'blocs/debt/debt_bloc.dart';

// Import Services
import 'services/product_service.dart';
import 'services/customer_service.dart';
import 'services/debt_service.dart';

// Import Screens
import 'screens/product/product_list_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/debt/debt_list_screen.dart'; // Make sure this file exists

// Import Theme
import 'utils/theme.dart'; //

void main() {
  // If you have any global initializations (e.g., for service locators like GetIt),
  // they would go here. For now, services are instantiated directly.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductService productService = ProductService();
    final CustomerService customerService = CustomerService();
    final DebtService debtService = DebtService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
          create:
              (context) => ProductBloc(productService)..add(
                const LoadProducts(),
              ), // CORRECTED: Create an instance of the event
        ),
        BlocProvider<CustomerBloc>(
          create:
              (context) => CustomerBloc(customerService: customerService)..add(
                const LoadCustomers(refresh: true),
              ), // CORRECTED: Instance with const if applicable
        ),
        BlocProvider<DebtBloc>(
          create:
              (context) => DebtBloc(
                debtService: debtService,
                customerService: customerService,
              )..add(
                const LoadDebts(refresh: true),
              ), // CORRECTED: Instance with const if applicable
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Warunku',
        theme: AppTheme.lightTheme,
        home: const MainNavigator(),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0; // Default to Products screen

  static final List<Widget> _widgetOptions = <Widget>[
    ProductListScreen(), // Your existing ProductListScreen
    const CustomerListScreen(),
    const DebtListScreen(), // Screen for listing debts
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to preserve state of screens in BottomNav
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Debts',
          ),
        ],
        currentIndex: _selectedIndex,
        // selectedItemColor: Theme.of(context).primaryColor, // This often comes from AppTheme
        // unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Or .shifting if you prefer
      ),
    );
  }
}
