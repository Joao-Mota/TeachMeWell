import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_rating_native/flutter_rating_native.dart';

class TeacherDetails {
  final String rowid;
  final String name;
  final String name_simpl;
  final String faculty;
  final int code;

  TeacherDetails(this.rowid, this.name, this.name_simpl, this.faculty, this.code);
}

class AllTeachersPage extends StatefulWidget {
  @override
  _AllTeachersPageState createState() {
    return new _AllTeachersPageState();
  }
}

Future<List<TeacherDetails>> getTeachersDetails() async {
  List<TeacherDetails> l = [];
  var querySnapshot = await FirebaseFirestore.instance.collection("professor").get();

  for (var element in querySnapshot.docs) {
    String rowid = element.id.toString();
    String name = element.data()['nome'].toString();
    String name_simpl = element.data()['nome-simpl'].toString();
    String faculty = element.data()['faculdade'].toString();
    int code = int.parse(element.data()['codigo'].toString());
    l.add(TeacherDetails(rowid, name, name_simpl, faculty, code));
  }

  return l;
}

class _AllTeachersPageState extends State<AllTeachersPage> {
  TextEditingController _textEditingController = TextEditingController();

  List<TeacherDetails> teacherDetailsListOnSearch = [];
  List<TeacherDetails> teacherDetailsList = [];

  _AllTeachersPageState() {
    getTeachersDetails().then((val) => setState(() {
      teacherDetailsList = val;
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
                  teacherDetailsListOnSearch = search(teacherDetailsList, _textEditingController.text, 1);
                });
              },
              controller: _textEditingController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Pesquisar...'),
          )
        ),
      ),
      body: teacherDetailsList.isEmpty?
          Center(
            child:
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'A carregar...',
                    style : TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          )
          : teacherDetailsListOnSearch.isEmpty && _textEditingController.text.isNotEmpty?
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
                  ],
              ),
          ) :
        ListView.builder(
            itemCount: _textEditingController.text.isNotEmpty? teacherDetailsListOnSearch.length : teacherDetailsList.length,
            itemBuilder: (_, index) {
              TeacherDetails teacher = _textEditingController.text.isNotEmpty? teacherDetailsListOnSearch[index] : teacherDetailsList[index];

              return ListTile(
                  title: Row(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 33,
                          child: CircleAvatar(
                            foregroundImage: NetworkImage('https://sigarra.up.pt/${teacher.faculty.toLowerCase()}/pt/FOTOGRAFIAS_SERVICE.foto?pct_cod=${teacher.code}'),
                            backgroundImage: const NetworkImage('https://www.der-windows-papst.de/wp-content/uploads/2019/03/Windows-Change-Default-Avatar-448x400.png'),
                            radius: 30,
                            onBackgroundImageError: (e, s) {
                              debugPrint('image issue, $e,$s');
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        //child: Text(teacher.name, style: const TextStyle(fontSize: 22.0, color: Colors.black),),
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                teacher.name,
                                style: const TextStyle(fontSize: 22.0, color: Colors.black),
                              ),
                            ),
                            Container(
                              alignment: Alignment.bottomLeft,
                              child: Text(teacher.faculty),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          decoration: const BoxDecoration(
                            color: Color(0xffddddff),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            '0',
                            style: Theme.of(context).textTheme.headlineMedium,
                          )
                      ),
                    ],
                  ),
                  onTap: () async {
                    final CollectionReference colRef = FirebaseFirestore.instance.collection('professor');

                    final DocumentReference docRef = colRef.doc(teacher.rowid);

                    final DocumentSnapshot documentSnapshot = await docRef.get();

                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TeacherPage(documentSnapshot)
                    ));
                  }
              );
            },
          )
    );
  }
}

List<TeacherDetails> search(List<TeacherDetails> names, String source, int number_of_errors_per_word) {
  List<TeacherDetails> ret = [];

  var l_source = source.split(" ");

  for(var e in l_source){
    if(e == '')
      l_source.remove(e);
  }

  for(var element in names){
    String s = element.name_simpl;
    var l_element = s.split(" ");

    int i = 0, j = 0;
    while (j < l_source.length && i < l_element.length) {
      int m = minimumEditDistance(l_source[j], l_element[i]);
      if (m <= number_of_errors_per_word) {
        j++;
      }
      i++;
      if (j == l_source.length) {
        ret.add(element);
        //ret.add(Triplet<String,String, String>(s, element.b, element.c));
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

class TeacherPage extends StatelessWidget {
  final DocumentSnapshot document;

  TeacherPage(this.document);

  @override
  Widget build(BuildContext context) {

    final GlobalKey<FormState> formKey = GlobalKey();
    final titulo = TextEditingController();
    final comentario = TextEditingController();

    double relacionamento = 0;
    double interesse = 0;
    double regras = 0;
    double disponibilidade = 0;
    double empenho = 0;
    double exigencia = 0;
    double conteudos = 0;
    double reflexao = 0;
    double ensino = 0;
    double mediaSingle = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(document['nome']),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(15.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 55,
                    child: CircleAvatar(
                      foregroundImage: NetworkImage('https://sigarra.up.pt/${document['faculdade'].toString().toLowerCase()}/pt/FOTOGRAFIAS_SERVICE.foto?pct_cod=${document['codigo']}'),
                      backgroundImage: const NetworkImage('https://www.der-windows-papst.de/wp-content/uploads/2019/03/Windows-Change-Default-Avatar-448x400.png'),
                      radius: 50,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(document['nome'], style: Theme.of(context).textTheme.headlineSmall,),
                ),
              ],
            ),
            SizedBox(
              child: Text(document['faculdade'], style: Theme.of(context).textTheme.headlineSmall,),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    scrollable: true,
                    content: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          const SizedBox(
                            child: Text('Bom Relacionamento com os Estudantes'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              relacionamento = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Capacidade de Estimular o Interesse'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              interesse = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Cumprimento das Regras de Avaliação'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              regras = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Disponibilidade'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              disponibilidade = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Empenho'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              empenho = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Exigência'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              exigencia = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Organização dos Conteúdos'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              conteudos = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Promoção da Reflexão'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              reflexao = rating;
                            },
                          ),
                          const SizedBox(
                            child: Text('Qualidade do Ensino'),
                          ),
                          RatingBar.builder(
                            minRating: 0.5,
                            maxRating: 5,
                            allowHalfRating: true,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            onRatingUpdate: (rating) {
                              ensino = rating;
                            },
                          ),
                          TextFormField(
                            controller: titulo,
                            decoration: const InputDecoration(
                              labelText: 'Titulo',
                              hintText: 'Escreva uma breve descrição',
                            ),
                            maxLength: 20,
                          ),
                          TextFormField(
                            controller: comentario,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              hintText: 'Comentário',
                              filled: true,
                            ),
                            maxLines: 5,
                            maxLength: 500,
                            textInputAction: TextInputAction.done,
                            validator: (String? text) {
                              if(text == null || text.isEmpty) {
                                return 'Please enter a value';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                          onPressed: () async {
                            String aux = titulo.text.replaceAll(" ", "");
                            if(aux == "") {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Erro de Input'),
                                  content: const Text('O Título não deve estar vazio'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, 'OK'),
                                      child: const Text('OK'),
                                    )
                                  ],
                                ),
                              );
                            }
                            else if(relacionamento == 0 || interesse == 0 || regras == 0 || disponibilidade == 0 || exigencia == 0 || conteudos == 0 || reflexao == 0 || ensino == 0){
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Erro de Input'),
                                  content: const Text('Nenhum rating deve ficar por preencher!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, 'OK'),
                                      child: const Text('OK'),
                                    )
                                  ],
                                ),
                              );
                            }
                            else {
                              mediaSingle = (relacionamento + interesse + regras + disponibilidade + empenho + exigencia + conteudos + reflexao + ensino) / 9;
                              addRating(relacionamento, interesse, regras, disponibilidade, empenho, exigencia, conteudos, reflexao, ensino, titulo.text, comentario.text, mediaSingle);
                              Navigator.pop(context, 'Submit');
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Comentário submetido'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, 'OK'),
                                      child: const Text('OK'),
                                    )
                                  ],
                                ),
                              );
                            }
                          },
                          child: const Text('Submit')
                      )
                    ],
                  ),
                );
              },
              child: const Text('Avaliar'),
            ),
            Container(
              height: 220,
              width: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: listRatings(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> addRating(double relacionamento, double interesse, double regras, double disponibilidade, double empenho, double exigencia, double conteudos, double reflexao, double ensino, String titulo, String comentario, double mediaSingle) async {
    final newDocument = FirebaseFirestore.instance.collection('avaliacao').doc();
    final json = {
      'bom relacionamento com os estudantes': relacionamento,
      'capacidade de estimular o interesse': interesse,
      'cumprimento das regras de avaliacao': regras,
      'disponibilidade': disponibilidade,
      'empenho': empenho,
      'exigencia': exigencia,
      'organizacao dos conteudos': conteudos,
      'promocao da reflexao': reflexao,
      'qualidade do ensino': ensino,
      'studentID': 202108677,
      'teacherID': document['codigo'].toString(),
      'titulo' : titulo,
      'comentario' : comentario,
      'media_single' : mediaSingle,
    };
    // Write to Firebase
    await newDocument.set(json);
  }

  Widget listRatings(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('avaliacao').where('teacherID', isEqualTo : document['codigo'].toString()).snapshots(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) return const Text('Loading...');
          return ListView.builder(
            itemExtent: 55.0,
            itemCount: (snapshot.data as QuerySnapshot).docs.length,
            itemBuilder:  (context, index) =>
                _buildListItem(context, (snapshot.data as QuerySnapshot).docs[index]),
          );
        }
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document2) {

    return ListTile(
      title:
      Row(
        children: [
          Expanded(
            child: Text(
              document2['titulo'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
              decoration: const BoxDecoration(
                color: Color(0xffddddff),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Text(
                document2['media_single'].toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium,
              )
          )
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            content: Column(
              children: [
                const SizedBox(child: Text('Bom Relacionamento com os Estudantes'),),
                SizedBox(
                  child: FlutterRating (rating: document2['bom relacionamento com os estudantes'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Capacidade de Estimular o Interesse'),),
                SizedBox(
                  child: FlutterRating (rating: document2['capacidade de estimular o interesse'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Cumprimento das Regras de Avaliação'),),
                SizedBox(
                  child: FlutterRating (rating: document2['cumprimento das regras de avaliacao'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Disponibilidade'),),
                SizedBox(
                  child: FlutterRating (rating: document2['disponibilidade'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Empenho'),),
                SizedBox(
                  child: FlutterRating (rating: document2['empenho'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Exigência'),),
                SizedBox(
                  child: FlutterRating (rating: document2['exigencia'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Organização dos Conteúdos'),),
                SizedBox(
                  child: FlutterRating (rating: document2['organizacao dos conteudos'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Promoção da Reflexão'),),
                SizedBox(
                  child: FlutterRating (rating: document2['promocao da reflexao'], size: 40, color: Colors.orange),
                ),
                const SizedBox(child: Text('Qualidade do Ensino'),),
                SizedBox(
                  child: FlutterRating (rating: document2['qualidade do ensino'], size: 40, color: Colors.orange),
                ),
                Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Center(
                      child: Text(document2['titulo']),
                    )
                ),
                Container(
                    height: 220,
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: SizedBox(
                      child: SingleChildScrollView(
                        child: Text(document2['comentario']),
                      ),
                    )
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FacultyTeachers extends StatelessWidget {
  final DocumentSnapshot document;
  final String faculdade;

  FacultyTeachers(this.document, this.faculdade);

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          title: const Text("Professores"),
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('professor').where('faculdade', isEqualTo: faculdade).snapshots(),
            builder: (context, snapshot) {
              if(!snapshot.hasData) return const Text('A carregar...');
              return ListView.builder(
                itemExtent: 80.0,
                itemCount: (snapshot.data as QuerySnapshot).docs.length,
                itemBuilder:  (context, index) =>
                    _buildListItem(context, (snapshot.data as QuerySnapshot).docs[index]),
              );
            }
        )
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {

    return ListTile(
        title: OpenContainer(
          closedColor: Colors.transparent,
          closedElevation: 0,
          openColor: Colors.transparent,
          openElevation: 0,
          transitionDuration: const Duration(milliseconds: 400),
          transitionType: ContainerTransitionType.fadeThrough,
          openBuilder: (context, _) => TeacherPage(document),
          closedBuilder: (context, VoidCallback openContainer) => Row(
            children: [
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 33,
                  child: CircleAvatar(
                    foregroundImage: NetworkImage('https://sigarra.up.pt/${document['faculdade'].toString().toLowerCase()}/pt/FOTOGRAFIAS_SERVICE.foto?pct_cod=${document['codigo']}'),
                    backgroundImage: const NetworkImage('https://www.der-windows-papst.de/wp-content/uploads/2019/03/Windows-Change-Default-Avatar-448x400.png'),
                    radius: 30,
                    onBackgroundImageError: (e, s) {
                      debugPrint('image issue, $e,$s');
                    },
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  document['nome'],
                  style: const TextStyle(fontSize: 22.0, color: Colors.black),
                ),
              ),
              Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffddddff),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    '0',
                    style: Theme.of(context).textTheme.headlineMedium,
                  )
              )
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherPage(document),
            ),
          );
        }
    );
  }
}
