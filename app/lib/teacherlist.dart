import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);
}

class AllTeachersPage extends StatefulWidget {
  @override
  _AllTeachersPageState createState() {
    return new _AllTeachersPageState();
  }
}

Future<List<Pair<String, String>>> getTeachersNames() async {
  List<Pair<String, String>> l = [];
  var querySnapshot = await FirebaseFirestore.instance.collection("professor").get();

  for (var element in querySnapshot.docs) {
    String name = element.data()['nome'].toString();
    String faculty = element.data()['faculdade'].toString();
    l.add(Pair<String, String>(name, faculty));
  }

  return l;
}

class _AllTeachersPageState extends State<AllTeachersPage> {
  TextEditingController _textEditingController = TextEditingController();

  List<Pair<String, String>> nameListOnSearch = [];
  List<Pair<String, String>> nameList = [];

  _AllTeachersPageState() {
    getTeachersNames().then((val) => setState(() {
      nameList = val;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  nameListOnSearch = search(nameList, _textEditingController.text, 2);
                });
              },
              controller: _textEditingController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Pequisar...'),
          )
        ),
      ),
      body: nameListOnSearch.isEmpty && _textEditingController!.text.isNotEmpty?
          Center (
            child:
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sem resultados',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
              ),
          ) :
        ListView.builder(
            itemCount: _textEditingController!.text.isNotEmpty? nameListOnSearch.length : nameList.length,
            itemBuilder: (_, index) {
              return Row(
                children: [
                  SizedBox(height: 50,),
                  Row(
                    children: [
                      SizedBox(height: 40,),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width)-5,
                        child: Text(
                          overflow: TextOverflow.ellipsis,
                          _textEditingController!.text.isNotEmpty? nameListOnSearch[index].a : nameList[index].a,
                          style: TextStyle(fontSize: 20,),
                        ),
                      ),
                    ],
                  ),
                  /*Row(
                    children: [
                      SizedBox(height: 10,),
                      Text(
                        _textEditingController!.text.isNotEmpty? nameListOnSearch[index].b : nameList[index].b,
                        style: TextStyle(fontSize: 13,),
                      )
                    ],
                  ),*/
                ],
              );
            },
          )
    );
  }
}

List<Pair<String, String>> search(List<Pair<String, String>> names, String source, int number_of_errors_per_word) {
  List<Pair<String, String>> ret = [];

  var l_source = source.split(" ");

  for(var element in names){
    String s = element.a;
    var l_element = s.split(" ");

    int i = 0, j = 0;
    while (j < l_source.length && i < l_element.length) {
      int m = minimumEditDistance(l_source[j], l_element[i]);
      if (m < number_of_errors_per_word) {
        j++;
      }
      i++;
      if (j == l_source.length) {
        ret.add(Pair<String, String>(s, element.b));
      }
    }
  }

  return ret;
}


int minimumEditDistance(String source, String target) {
  int n = source.length;
  int m = target.length;

  // Create the dp matrix
  List<List<int>> dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));

  // Initialize the base cases
  for (int i = 0; i <= n; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= m; j++) {
    dp[0][j] = j;
  }

  // Fill the dp matrix using dynamic programming
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      if (source[i - 1] == target[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b) + 1;
      }
    }
  }

  return dp[n][m];
}

/*
class ProfileDetails extends StatelessWidget {
  final DocumentSnapshot document;

  ProfileDetails(this.document);

  Widget _buildListItem(BuildContext context, DocumentSnapshot document2) {

    return ListTile(
        title: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          DocumentReference documentReference = FirebaseFirestore.instance.collection('comments').doc(document2.id);
          documentReference.delete();
        },
        child:
        Row(
          children: [
            Expanded(
              child: Text(
                document2['description'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Container(
                decoration: const BoxDecoration(
                  color: Color(0xffddddff),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  document2['rating'].toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
            )
          ],
        ),
        ),
    );
  }

  Future<dynamic> addComment(String description, double rating) async {
    final newDocument = FirebaseFirestore.instance.collection('comments').doc();
    final json = { 'description': description, 'rating': rating, 'teacher': int.parse(document.id) };

    // Write to Firebase
    await newDocument.set(json);
  }

  @override
  Widget build(BuildContext context) {
    final description = TextEditingController();
    final rating = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(document['name']),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.network('https://sigarra.up.pt/feup/pt/FOTOGRAFIAS_SERVICE.foto?pct_cod=' + document.id),
              Text(document['name'], style: Theme.of(context).textTheme.headlineMedium,),
              Text(document['department'], style: Theme.of(context).textTheme.headlineSmall,),
              Container(
                height: 220,
                width: 400,
                child: listComments(context),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
              ),
              Text('\n\nComment:'),
              TextFormField(
                controller: description,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
              TextFormField(
                controller: rating,
                decoration: InputDecoration(
                  labelText: 'Rating',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final d = description.text;
                  final r_temp = rating.text;
                  double r;

                  try {
                    r = double.parse(r_temp);
                    if(r >= 0 && r <= 5) {
                      addComment(d, r);
                      description.clear();
                      rating.clear();
                    }
                  } catch (e) {}
                },
                child : Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget listComments(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('comments').where('teacher', isEqualTo: int.parse(document.id) ).snapshots(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) return const Text('Loading...');
          return ListView.builder(
            itemExtent: 80.0,
            itemCount: (snapshot.data as QuerySnapshot).docs.length,
            itemBuilder:  (context, index) =>
                _buildListItem(context, (snapshot.data as QuerySnapshot).docs[index]),
          );
        }
    );
  }
}
*/