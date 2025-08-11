
/*Donc cette classe AuthService t9oum bel service d'inscription :
s'authentifie,
tab3ath email de vérification,
w tsajjel les données mtaʿ l'utilisateur fi Firestore.*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  //objet privé f dart objet privé ykoun kablou _
  //enajem nchoufou ken fi west l page hedhi
  final FirebaseAuth _auth = FirebaseAuth.instance; //objet fourni par Firebase, qui permet de gérer l’authentification.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // objet Firebase pour accéder à la base de données Firestore.

  Future<String?> registerUser({
    required String nom,
    required String email,
    required String password,
    String role = 'client', 
    //required String cultures,
  }) async {
    try {

      //taamel création l user fel firebase authentification w thotha fel result eli howa type te3ou UserCredential
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //houni khdhina l user m result.user
      User? user = result.user; //.user propriétes men UserCredential

      if (user != null) {
        // senEmailVerification tabaath email lel user eli kayadneh
        await user.sendEmailVerification();

        // ki yetsajel naamlou collection jdida fel firestore besh nhotou feha les donénes taa l user 
        await _firestore.collection('users').doc(user.uid).set({
          'nom': nom,
          'email': email,
          //'cultures': cultures,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'client',
          //'password':password,
        });

        //user.uid : propriété générée automatiquement par Firebase (identifiant unique)
        //user najem nbadel esmha kima nheb ama lazem nbadlou wakt makhdhit l user m result w zeda lazem nbadalha f doc(...)

        return null; // ken kol chy mrigel matrajaali chy
      } else {
        return "Erreur lors de la création de l'utilisateur.";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Une erreur inconnue est survenue.";
    }
  }



  
}
