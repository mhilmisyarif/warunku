import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(85),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.white,
            flexibleSpace: Positioned(
                top: 16,
                left: 10,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.fromLTRB(18, 35, 0, 0),
                  child: const Stack(
                    children: [
                      Positioned(
                          left: 0,
                          top: 0,
                          child: Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          )),
                      Positioned(
                        left: 0,
                        top: 29,
                        child: Text(
                          // '${currentUser.name}',
                          'User',
                          style: TextStyle(
                            color: Color(0xFF102C57),
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  ),
                )),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.lightbulb_outlined,
                        color: Color(0xFF102C57), size: 34)),
              )
            ],
          )),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Warunku!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "This is a simple app to help you track your expenses.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "To get started, click the button below.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/buy');
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Get Started"),
            ),
          ],
        ),
      ),
    );
  }
}
