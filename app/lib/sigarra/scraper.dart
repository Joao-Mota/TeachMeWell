import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<void> fakeMain2() async{
  print("Started fakeMain2");
  List<int> t = await getCourseUCsIDs("fcup", 13221, 2022);
  for(int i in t){
    print(i);
  }
  print("Ended fakeMain2");
}

String removeDiacritics(String str) {
  var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

bool isInList(List<int> l, int n) {
  for (int i in l) {
    if (i == n) {return true;}
  }
  return false;
}

Future<List<int>> getTeacherUCsIDs(String faculty, int teacher, int year) async {
  final response = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/ds_func_relatorios.querylist?pv_doc_codigo=$teacher&pv_outras_inst=S&pv_ano_lectivo=$year'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var table = soup.find('*', id: 'conteudoinner');
  table = table!.find('table');
  var rows = table!.findAll('tr');
  rows = rows.sublist(1, rows.length-3);

  List<int> ids = [];

  for (Bs4Element row in rows) {
    var a = row.find('a');
    String s = a.toString();
    s = s.substring(52, 58);
    int i = int.parse(s);
    if (!isInList(ids, i)) {
      ids.add(i);
    }
  }

  return ids;
}

Future<List<int>> getUCTeachersIDs(String faculty, int uc_id) async {
  print("Started getUCsTeachersIDs");
  List<int> teachers = [];

  // print("helo1");
  faculty = faculty.toLowerCase();
    final response = await http.Client().get(Uri.parse(
        'https://sigarra.up.pt/$faculty/pt/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=$uc_id'));
    String body = response.body;
    // print(uc_id);
    // print("helo2" );
    // print(body);

    BeautifulSoup soup = BeautifulSoup(body);

    var tables = soup.findAll('table', class_: 'dados');
    var table = null;
    for(var t in tables){
      // print("Searching for table");
      if(t.toString().contains("Turmas")){
        table = t;
        break;
      }
    }
    if(table == null)
      return [];
    var rows = table!.findAll('td', class_:"t");

    for (var row in rows) {
      // print("Searching for row");
      var a = row.find('a');
      var a_string = a.toString();
      // print(a_string);
      if (a != null && a_string.substring(29, 37) == "p_codigo")
        teachers.add(int.parse(a_string.substring(38, 44)));
    }

  // print("Reached end of getUCsTeachersIDs");
  print(teachers);

  return teachers;
}

bool isInDocumentSnapshotList(List<DocumentSnapshot> l, DocumentSnapshot document) {
  for (DocumentSnapshot d in l) {
    if (d == document) return true;
  }

  return false;
}

void sortDocumentSnapshotList(List<DocumentSnapshot> l) {
  l.sort((a, b) => a['nome'].compareTo(b['nome']));
}

Future<List<DocumentSnapshot>> getUCTeachers(String faculty, int uc_id) async {
  List<DocumentSnapshot> ret = [];

  List<int> ids = await getUCTeachersIDs(faculty, uc_id);

  for (int id in ids) {
    QuerySnapshot query = await FirebaseFirestore.instance.collection('professor')
        .where('codigo', isEqualTo: id)
        .where('faculdade', isEqualTo: faculty).get();
    print(id.toString() + ' ' + uc_id.toString());

    if (query.docs.length > 0) {
      DocumentSnapshot document = query.docs.first;
      if (!isInDocumentSnapshotList(ret, document)) ret.add(document);
    }
  }

  sortDocumentSnapshotList(ret);

  return ret;
}

Stream<QuerySnapshot> getUCsTeachersStream(String faculty, int uc_id) async* {
  List<int> ids = await getUCTeachersIDs(faculty, uc_id);

  for(int i in ids){
    var i_query = FirebaseFirestore.instance.collection('professor').where('id', isEqualTo: i).where('faculdade', isEqualTo: faculty.toUpperCase()).snapshots();
    await for(QuerySnapshot i_res in i_query) {
      print(i_res.docs[0]['nome']);
      yield i_res;
    }
  }
}

dynamic UCsCount = null;
bool awaitRet = false;

// Future<void> getUCsTeachersLengthAwait(String faculty, int uc_id) async {
//   print("Started getUCsTeachersLengthAwait");
//   Set<int> s = await getUCsTeachersIDs(faculty, uc_id);
//   UCsCount = s.length;
//   awaitRet = true;
// }
/*
int getUCsTeachersLength(String faculty, int uc_id) {
  getUCsTeachersIDs(faculty, uc_id).then(
          (List<int> s) {
            print("Ended getUCsTeachersLength");
            UCsCount = s.length; awaitRet = true;
          });
  while(!awaitRet){
    print("Waiting for awaitRet");
    sleep(Duration(seconds: 1));
  }
  int ret = UCsCount;
  UCsCount = null;
  awaitRet = false;
  print("Returning $ret");
  return ret;
}*/

// Future<int> getUCsTeachersLength(String faculty, int uc_id) async{
//   Set<int> s = await getUCsTeachersIDs(faculty, uc_id);
//   // print("Ended getUCsTeachersLength");
//   return s.length;
// }

Future<List<int>> getCourseUCsIDs(String faculty, int curso, int ano_letivo) async {
  faculty = faculty.toLowerCase();
  // print("faculdade: $faculty, curso: $curso, ano_letivo: $ano_letivo");
  final response_before = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/cur_geral.cur_view?pv_curso_id=$curso&pv_ano_lectivo=$ano_letivo'));
  String body_before = response_before.body;

  BeautifulSoup soup_before = BeautifulSoup(body_before);
  var table_before = soup_before.find('*', id: 'conteudoinner');
  var li_before = table_before!.findAll('li');
  int id_before = 0;

  for(var li in li_before) {
    var a_before = li!.findAll('a');
    for (var a in a_before) {
      String s = a.toString();
      if (s.contains("Plano ")) {
        print(s);
        int i = 55;
        String char = s.substring(55, 56);
        while (true) {
          try {
            int.parse(char);
          } catch (e) {
            break;
          }
          i++;
          char = s.substring(i, i + 1);
        }
        try {
          id_before = int.parse(s.substring(55, i));
        } catch (e) {
          print("Helloo!!!!");
          print(curso);
          print(s.substring(55, i));
          throw e;
        }
        break;
      }
    }
  }

  // print("id_before: $id_before");

  final response = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/cur_geral.cur_planos_estudos_view?pv_plano_id=$id_before&pv_ano_lectivo=$ano_letivo'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var table = soup.find('*', id: 'conteudoinner');
  var as = table!.findAll('a');

  List<int> ids = [];

  for (var a in as) {
    String s = a.toString();
    // print(s);
    if(s.length < 51 || s.substring(35, 51) != "pv_ocorrencia_id")
      continue;
    // print(s.substring(35, 51));
    int i = 52;
    String char = s.substring(52, 56);
    while(true){
      try {
        int.parse(char);
      } catch (e) {
        break;
      }
      i++;
      char = s.substring(i, i+1);
    }

    int id = int.parse(s.substring(52, i));
    if (!isInList(ids, id)) {
      ids.add(id);
    }
  }
  return ids;
}

Stream<UC_details> getCourseUCsIDsStream(String faculty, int curso, int ano_letivo) async* {
  for (var i in await getCourseUCsIDs(faculty, curso, ano_letivo)) {
    yield await getUCInfo(faculty, i);
  }
}

class UC_details {
  String nome;
  String codigo;
  String acronimo;
  String faculdade;
  int id;

  UC_details(this.nome, this.codigo, this.acronimo, this.faculdade, this.id);
}

Future<UC_details> getUCInfo(String faculty, int id) async {
  faculty = faculty.toLowerCase();
  // print("faculdade: $faculty, id: $id");
  final response = await http.Client().get(Uri.parse(
      'https://sigarra.up.pt/$faculty/pt/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=$id'));
  String body = response.body;
  BeautifulSoup soup = BeautifulSoup(body);
  try {
    var content = soup.find('*', id: 'conteudoinner');
    var h1 = content!.findAll('h1');
    var table = soup.find('*', class_: 'formulario');
    var td = table!.findAll('td');

    String nome = h1[1].toString();
    nome = nome.substring(4, (nome.length) - 5);

    String codigo = td[1].toString();
    codigo = codigo.substring(4, (codigo.length) - 5);

    String acronimo = td[4].toString();
    acronimo = acronimo.substring(4, (acronimo.length) - 5);

    return UC_details(nome, codigo, acronimo, faculty, id);
  } catch (e) {
    try {
      var meta = soup.findAll('meta');
      bool found = false;

      for (var m in meta) {
        found = true;
        if (m.toString().contains("url=")) {
          String s = m.toString();
          // print(s);
          int i = 63;
          String char = s.substring(63, 64);
          while (char != "/") {
            i++;
            char = s.substring(i, i + 1);
          }
          // print(s.substring(63, i));
          return await getUCInfo(s.substring(63, i), id);
        }
      }
      if (!found) {
        return UC_details("", "", "", "", 0);
      }
    } catch (e) {
      return UC_details("", "", "", "", 0);
    }
  }
  return UC_details("", "", "", "", 0);
}

Future<List<int>> getFacultyBachelorsIDs(String faculty) async {
  final response = await http.Client().get(Uri.parse('https://www.up.pt/portal/pt/estudar/licenciaturas-e-mestrados-integrados/oferta-formativa/'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var dl = soup.find('*', id: 'facultyList');
  var as = dl!.findAll('a');

  List<int> ids = [];

  for (var a in as) {
    String href = a['href'].toString();
    //print(a.toString());
    String f = href.substring(73, 73 + (faculty.length));
    //print("f: " + f);
    //print(f == faculty);
    String id = href.substring(74 + (faculty.length), (href.length) - 1);
    //print("id: " + id);
    if (f == faculty) {
      ids.add(int.parse(id));
    }
  }

  return ids;
}

Future<List<int>> getFacultyMastersIDs(String faculty) async {
  final response = await http.Client().get(Uri.parse('https://www.up.pt/portal/pt/estudar/mestrados/oferta-formativa/'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var dl = soup.find('*', id: 'facultyList');
  var as = dl!.findAll('a');

  List<int> ids = [];

  for (var a in as) {
    String href = a['href'].toString();
    //print(a.toString());
    String f = href.substring(46, 46 + (faculty.length));
    //print("f: " + f);
    //print(f == faculty);
    String id = href.substring(47 + (faculty.length), (href.length) - 1);
    //print("id: " + id);
    if (f == faculty) {
      ids.add(int.parse(id));
    }
  }

  return ids;
}

Future<List<int>> getFacultyPhDsIDs(String faculty) async {
  final response = await http.Client().get(Uri.parse('https://www.up.pt/portal/pt/estudar/doutoramentos/oferta-formativa/'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var dl = soup.find('*', id: 'facultyList');
  var as = dl!.findAll('a');

  List<int> ids = [];

  for (var a in as) {
    String href = a['href'].toString();
    //print(a.toString());
    String f = href.substring(50, 50 + (faculty.length));
    //print("f: " + f);
    //print(f == faculty);
    String id = href.substring(51 + (faculty.length), (href.length) - 1);
    //print("id: " + id);
    if (f == faculty) {
      ids.add(int.parse(id));
    }
  }

  return ids;
}

class Course {
  String grau;
  String nome;
  String sigla;
  String faculdade;
  int id;

  Course(this.grau, this.nome, this.sigla, this.faculdade, this.id);
}

Future<Course> getCourse(String faculty, int id, String degree) async {
  final response = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/cur_geral.cur_view?pv_curso_id=$id'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var content = soup.find('*', id: 'conteudoinner');
  String nome = content!.findAll('h1')[1]!.text.toString();

  var span = soup.find('span', class_: 'pagina-atual');
  String sigla = span!.text.toString().substring(3);

  String grau;

  if (nome == 'Criminologia' || nome == 'Direito') grau = 'Licenciatura';
  else if (nome.substring(0, 12) == 'Licenciatura') grau = 'Licenciatura';
  else if (nome.substring(0, 18) == 'Mestrado Integrado') grau = 'Mestrado Integrado';
  else grau = degree;

  return Course(grau, nome, sigla, faculty.toUpperCase(), id);
}

List<String> faculties = ['fcup', 'fcnaup', 'fadeup', 'fdup', 'fep', 'feup', 'flup', 'fmup', 'fpceup', 'icbas'];

