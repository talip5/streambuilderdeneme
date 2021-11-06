import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/ImageUploadPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signin_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  bool wacthedPush;
  QuerySnapshot querySnapshot;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cloud Firestore"),
        actions: [
          //! Builder eklemezsek Scaffold.of() hata verecektir!
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.login),
              onPressed: () async {
                await _auth.signOut();
                if (await GoogleSignIn().isSignedIn()) {
                  print("google user");
                  await GoogleSignIn().disconnect();
                  await GoogleSignIn().signOut();
                }

                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text("Başarıyla çıkış yapıldı"),
                ));

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(),
                  ),
                );
              },
            ),
          )
        ],
      ),

      //StreamBuilder, FutureBuilder ile benzer çalışır ama ondan farklı olarak
      // verilen dökümanda yapılan en küçük değişiklikler ekrana yansıtılır ve setState e gerek kalmaz.
      //StatelessWidget' ta bile yaplan değişiklikler ekrana yansır.
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("movies")
        //.where("isWatched", isEqualTo: true)
            .orderBy("year", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Icon(Icons.error, size: 80),
            );
          }
          final querySnapshot = snapshot.data;
          return ListView.builder(
            itemCount: querySnapshot.size,
            itemBuilder: (context, index) {
              final map = querySnapshot.docs[index].data();
              return Dismissible(
                key: Key(querySnapshot.docs[index].id),
                onDismissed: (direction) async {
                  await querySnapshot.docs[index].reference.delete();
                },
                child: ListTile(
                  onLongPress: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ImageUploadPage()));
                  },
                  onTap: () => _watch(
                      map["isWatched"], querySnapshot.docs[index].reference),
                  leading: map["image"] != null
                      ? Image.network(map["image"])
                      : SizedBox.shrink(),
                  title: Text(map["title"]),
                  subtitle: map["year"] != null ? Text("${map["year"]}") : null,
                  trailing: map["isWatched"] == true
                      ? Icon(Icons.check_box)
                      : SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Wrap(
          spacing: 10,
          children: [
            RaisedButton(
              child:Icon(
                Icons.add,
                size: 30,
              ),
              //tooltip: "Film Ekle",
              onPressed: () async {
                await FirebaseFirestore.instance.collection("movies").add({
                  "title": "Yeni Film",
                  "year": "2025",
                });
              },
            ),
            FloatingActionButton.extended(
                label: Text("filmleri filtrele"),
                icon: Icon(Icons.filter_alt),
                onPressed: ()async{
                  wacthedPush = true;
                  var gelen  = await FirebaseFirestore.instance.collection("movies")
                      .where("isWatched", isEqualTo: true).snapshots().map((event) => null);
                  debugPrint(gelen.toString());
                })
          ]),
    );
  }

  void _watch(bool watch, DocumentReference ref) async {
    bool isWatched = true;
    if (watch == true) {
      isWatched = false;
    }
    await ref.update({"isWatched": isWatched});
  }
}


FloatingActionButton.extended(
label: Text("filmleri filtrele"),
icon: Icon(Icons.filter_alt),
onPressed: () async {
wacthedPush = true;

Widget setupAlertDialogContainer() {
  return Container(
    height: 300, width: 300,
    child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("movies").where("isWatched", isEqualTo: true).snapshots(),
        builder: (context, snapshot){
          final _querySnapshot = snapshot.data;
          return ListView.builder(
              itemCount: _querySnapshot.size,
              itemBuilder: (BuildContext context, int index){
                final _map = _querySnapshot.docs[index].data();
                return ListTile(
                  title: Text(_map["title"]),
                );
              });
        }),
  );
}
showDialog(context: context, builder: (_) {
return AlertDialog(
title: Text("Movies watched"),
content: setupAlertDialogContainer(),
);
});
})