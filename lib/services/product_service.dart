import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addProduct({
    required String nome,
    required String categoria,
    required double precoCompra,
    required double precoVenda,
    required int quantidade,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('produtos')
        .add({
      'nome': nome,
      'categoria': categoria,
      'precoCompra': precoCompra,
      'precoVenda': precoVenda,
      'quantidade': quantidade,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getProducts() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('produtos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteProduct(String id) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('produtos')
        .doc(id)
        .delete();
  }
}