import 'package:flutter/material.dart';

class DetailItemScreen extends StatelessWidget {
  const DetailItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.white,
          title: const Padding(
            padding: EdgeInsets.fromLTRB(60, 0, 0, 0),
            child: Text(
              'Detail Item',
              style: TextStyle(
                color: Color(0xFF102C57),
                fontSize: 20,
                fontFamily: 'Inter',
              ),
            ),
          ),
          leading: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF102C57), size: 34))),
      body: const Center(
        child: Text('Detail Item'),
      ),
    );
  }
}
