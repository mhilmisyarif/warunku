// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/product_model.dart';
// import 'dart:developer';

// final db = FirebaseFirestore.instance;

// void addProduct({name, price, category, thumbnail}) async {
//   final docRef = db.collection('products').doc();
//   Product product = Product(
//     id: docRef.id,
//     name: name,
//     price: price,
//     category: category,
//     thumbnail: thumbnail,
//   );

//   await docRef.set(product.toJson()).then((value) => log("Product Added"),
//       onError: (error) => log("Failed to add product: $error"));

//   await db.collection('products').add(product.toJson());
// }

// void updateProduct(product) {
//   db.collection('products').doc(product.id).update(product.toJson()).then(
//       (value) => log("Product Updated"),
//       onError: (error) => log("Failed to update product: $error"));
// }

// void deleteProduct(product) {
//   db.collection('products').doc(product.id).delete().then((value) {
//     log("Product Deleted");
//   }).catchError((error) => log("Failed to delete product: $error"));
// }
