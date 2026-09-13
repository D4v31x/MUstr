import 'package:material_ui/material_ui.dart';

class Faculty {
  const Faculty({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameSk,
    required this.shortName,
    required this.color,
  });

  final String id;
  final String name;
  final String nameEn;
  final String nameSk;
  final String shortName;
  final Color color;

  Color get foregroundColor =>
      color.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  String localizedName(String languageCode) => switch (languageCode) {
    'en' => nameEn,
    'sk' => nameSk,
    _ => name,
  };
}

abstract final class MuniFaculties {
  static const all = <Faculty>[
    Faculty(
      id: 'prf',
      name: 'Právnická fakulta',
      nameEn: 'Faculty of Law',
      nameSk: 'Právnická fakulta',
      shortName: 'PrF',
      color: Color(0xff9100DC),
    ),
    Faculty(
      id: 'med',
      name: 'Lékařská fakulta',
      nameEn: 'Faculty of Medicine',
      nameSk: 'Lekárska fakulta',
      shortName: 'LF',
      color: Color(0xffF01928),
    ),
    Faculty(
      id: 'sci',
      name: 'Přírodovědecká fakulta',
      nameEn: 'Faculty of Science',
      nameSk: 'Prírodovedecká fakulta',
      shortName: 'PřF',
      color: Color(0xff00AF3F),
    ),
    Faculty(
      id: 'phil',
      name: 'Filozofická fakulta',
      nameEn: 'Faculty of Arts',
      nameSk: 'Filozofická fakulta',
      shortName: 'FF',
      color: Color(0xff4BC8FF),
    ),
    Faculty(
      id: 'ped',
      name: 'Pedagogická fakulta',
      nameEn: 'Faculty of Education',
      nameSk: 'Pedagogická fakulta',
      shortName: 'PdF',
      color: Color(0xffFF7300),
    ),
    Faculty(
      id: 'pharm',
      name: 'Farmaceutická fakulta',
      nameEn: 'Faculty of Pharmacy',
      nameSk: 'Farmaceutická fakulta',
      shortName: 'FaF',
      color: Color(0xff56788D),
    ),
    Faculty(
      id: 'econ',
      name: 'Ekonomicko-správní fakulta',
      nameEn: 'Faculty of Economics and Administration',
      nameSk: 'Ekonomicko-správna fakulta',
      shortName: 'ESF',
      color: Color(0xffB9006E),
    ),
    Faculty(
      id: 'fi',
      name: 'Fakulta informatiky',
      nameEn: 'Faculty of Informatics',
      nameSk: 'Fakulta informatiky',
      shortName: 'FI',
      color: Color(0xffF2D45C),
    ),
    Faculty(
      id: 'fss',
      name: 'Fakulta sociálních studií',
      nameEn: 'Faculty of Social Studies',
      nameSk: 'Fakulta sociálnych štúdií',
      shortName: 'FSS',
      color: Color(0xff007A53),
    ),
    Faculty(
      id: 'fsps',
      name: 'Fakulta sportovních studií',
      nameEn: 'Faculty of Sports Studies',
      nameSk: 'Fakulta športových štúdií',
      shortName: 'FSpS',
      color: Color(0xff5AC8AF),
    ),
  ];

  static Faculty? byId(String? id) =>
      id == null ? null : all.where((faculty) => faculty.id == id).firstOrNull;
}
