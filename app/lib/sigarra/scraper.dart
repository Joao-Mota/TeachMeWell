import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

fakeMain() async {
  // print('\n');
  // print(await getTeacherUCs("feup", 211636, 2022));
  // print('\n');
  // print(await getUCInfo('feup', 501680));
  // populateFCUPTeachers();
  // populateFCNAUPTeachers();
  // populateFADEUPTeachers();
  // populateFDUPTeachers();
  // populateFEPTeachers();
  // populateFEUPTeachers();
  // populateFLUPTeachers();
  // populateFMUPTeachers();
  // populateFPCEUPTeachers();
  // populateICBASTeachers();
}

Future<void> fakeMain2() async{
  print("Started fakeMain2");
  List<int> t = await getCursoUCs("fcup", 13221, 2022);
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

Future<List<int>> getTeacherUCs(String faculty, int teacher, int year) async {
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

Future<Set<int>> getUCsTeachers(String faculty, int uc_id) async {
  Set<int> teachers = {};

    final response = await http.Client().get(Uri.parse(
        'https://sigarra.up.pt/$faculty/pt/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=$uc_id'));
    String body = response.body;

    BeautifulSoup soup = BeautifulSoup(body);

    var tables = soup.findAll('table', class_: 'dados');
    var table = null;
    for(var t in tables){
      if(t.toString().contains("Turmas")){
        table = t;
        break;
      }
    }
    if(table == null)
      return {};
    var rows = table!.findAll('td', class_:"t");

    for (var row in rows) {
      var a = row.find('a');
      var a_string = a.toString();
      if (a != null && a_string.substring(29, 37) == "p_codigo")
        teachers.add(int.parse(a_string.substring(38, 44)));
    }

  return teachers;
}

Future<List<int>> getCursoUCs(String faculty, int curso, int ano_letivo) async {
  final response = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/cur_geral.cur_planos_estudos_view?pv_plano_id=$curso&pv_ano_lectivo=$ano_letivo'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var table = soup.find('*', id: 'conteudoinner');
  var as = table!.findAll('a');
  // table = table!.find('table');
  // var rows = table!.findAll('tr');
  // rows = rows.sublist(1, rows.length-3);

  List<int> ids = [];

  for (var a in as) {
    // var a = row.find('a');
    String s = a.toString();
    if(s.substring(9, 14) == "ucurr"){
      // print(s.substring(52, 58));
      try {
        int i = int.parse(s.substring(52, 58));
        // print(i);
        ids.add(i);
      } catch (e) {
        continue;
      }
      // if (!isInList(ids, i)) {
      //   print(i);
      //   // ids.add(i);
      // }
    }
    // s = s.substring(52, 58);
    // int i = int.parse(s);
    // if (!isInList(ids, i)) {
    //   ids.add(i);
    // }
  }

  return ids;
}

Future<List<String>> getUCInfo(String faculty, int id) async {
  final response = await http.Client().get(Uri.parse('https://sigarra.up.pt/$faculty/pt/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=$id'));
  String body = response.body;

  BeautifulSoup soup = BeautifulSoup(body);

  var content = soup.find('*', id: 'conteudoinner');
  var h1 = content!.findAll('h1');
  var table = soup.find('*', class_: 'formulario');
  var td = table!.findAll('td');

  String name = h1[1].toString();
  name = name.substring(4, (name.length) - 5);

  String code = td[1].toString();
  code = code.substring(4, (code.length) - 5);

  String acronym = td[4].toString();
  acronym = acronym.substring(4, (acronym.length) - 5);

  return [name, code, acronym];
}
