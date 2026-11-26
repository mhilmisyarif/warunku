import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'blocs/cart/cart_cubit.dart';
import 'blocs/customer/customer_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/debt/debt_list_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/sale/sale_list_screen.dart';
import 'services/api_client.dart';
import 'services/customer_service.dart';
import 'services/debt_service.dart';
import 'services/product_service.dart';
import 'services/sale_service.dart';
import 'utils/theme.dart';

void main() {
  runApp(WarunkuApp(apiClient: ApiClient()));
}

class WarunkuApp extends StatelessWidget {
  const WarunkuApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ProductService(apiClient)),
        RepositoryProvider(create: (_) => CustomerService(apiClient)),
        RepositoryProvider(create: (_) => DebtService(apiClient)),
        RepositoryProvider(create: (_) => SaleService(apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(
            create:
                (context) =>
                    ProductBloc(context.read<ProductService>())
                      ..add(const LoadProducts()),
          ),
          BlocProvider(
            create:
                (context) =>
                    CustomerBloc(context.read<CustomerService>())
                      ..add(const LoadCustomers()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Warunku',
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          supportedLocales: const [Locale('id')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const MainNavigator(),
        ),
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Each tab is a full Scaffold with its own app bar. Products and
    // customers stay mounted to keep their search; debts and sales are
    // rebuilt on each visit so they show what the cart just recorded.
    final tabs = <Widget>[
      const ProductListScreen(),
      const CustomerListScreen(),
      _selectedIndex == 2 ? const DebtListScreen() : const SizedBox.shrink(),
      _selectedIndex == 3 ? const SaleListScreen() : const SizedBox.shrink(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Utang',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Penjualan',
          ),
        ],
      ),
    );
  }
}
