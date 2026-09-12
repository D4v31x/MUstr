import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/data/parsers/muni_timetable_parser.dart';
import 'package:muni_timetable/domain/entities/timetable.dart';

void main() {
  final parser = MuniTimetableParser();

  test('parses actual MUNI slot details and non-standard times', () {
    final timetable = parser.parse(_xml);

    expect(timetable.semester, 'podzim2026');
    expect(timetable.lessons, hasLength(3));
    expect(timetable.subjects, hasLength(3));
    final systems = timetable.lessons.first;
    expect(systems.date, DateTime(2026, 9, 14));
    expect(systems.startTime, DateTime(2026, 9, 14, 9));
    expect(systems.endTime, DateTime(2026, 9, 14, 11, 50));
    expect(systems.rooms.single.name, '136');
    expect(systems.teachers.single.name, 'M. Brandejs');

    final onlineClass = timetable.lessons.last;
    expect(onlineClass.rooms.single.name, 'online výuka');
    expect(onlineClass.teachers.map((teacher) => teacher.name), [
      'M. Mareš',
      'D. Navrátil',
    ]);
    expect(onlineClass.duration, const Duration(hours: 1, minutes: 40));
  });

  test('allows missing rooms and teachers while keeping event data', () {
    final timetable = parser.parse('''
<rozvrh><tabulka><den id="Po 14. 9."><radek>
<slot odcas="09:10" docas="10:00"><akce><kod>TEST</kod><nazev>Test event</nazev><obdobi_url>podzim2026</obdobi_url></akce></slot>
</radek></den></tabulka></rozvrh>
''');

    expect(timetable.lessons.first.rooms, isEmpty);
    expect(timetable.lessons.first.teachers, isEmpty);
  });

  test('rejects malformed XML and ignores break entries', () {
    expect(() => parser.parse('<rozvrh><tabulka>'), throwsA(isA<TimetableParseException>()));
    expect(parser.parse(_xml).lessons, hasLength(3));
  });

  test('identifies course codes with a group as mandatory seminars', () {
    final timetable = parser.parse('''
<rozvrh><tabulka><den id="Po 14. 9."><radek>
<slot odcas="09:00" docas="10:00"><akce><kod>IB111/14</kod><nazev>Základy programování</nazev><predmetid>1726815</predmetid><obdobi_url>podzim2026</obdobi_url></akce></slot>
</radek></den></tabulka></rozvrh>
''');

    final seminar = timetable.lessons.single;
    expect(seminar.courseCode, 'IB111');
    expect(seminar.seminarGroup, '14');
    expect(seminar.kind, LessonKind.seminar);
    expect(seminar.isMandatory, isTrue);
  });
}

const _xml = '''
<rozvrh><tabulka>
<den id="Po 14. 9."><radek>
<break odcas="7:00" docas="8:00"/>
<slot odcas="09:00" docas="11:50"><mistnosti><mistnost><mistnostozn>136</mistnostozn><mistnostid>1297</mistnostid></mistnost></mistnosti><akce><kod>PB151</kod><nazev>Výpočetní systémy</nazev><predmetid>1726907</predmetid><fakulta_url>fi</fakulta_url><obdobi_url>podzim2026</obdobi_url></akce><ucitele><ucitel><ucitelid>2116</ucitelid><uciteljmeno>M. Brandejs</uciteljmeno></ucitel></ucitele></slot>
<slot odcas="15:00" docas="15:30"><mistnosti><mistnost><mistnostozn>A103</mistnostozn><mistnostid>395</mistnostid></mistnost></mistnosti><akce><kod>Naskoc00</kod><nazev>Přivítání na FI</nazev><predmetid>1726848</predmetid><fakulta_url>fi</fakulta_url><obdobi_url>podzim2026</obdobi_url></akce><ucitele/></slot>
</radek></den>
<den id="St 16. 9."><radek><slot odcas="14:00" docas="15:40"><mistnosti><mistnost><mistnostozn>online výuka</mistnostozn><mistnostid>14857</mistnostid></mistnost></mistnosti><akce><kod>BSSb1203</kod><nazev>Úvod do kyberbez. v pojetí BSS</nazev><predmetid>1783644</predmetid><fakulta_url>fss</fakulta_url><obdobi_url>podzim2026</obdobi_url></akce><ucitele><ucitel><ucitelid>922</ucitelid><uciteljmeno>M. Mareš</uciteljmeno></ucitel><ucitel><ucitelid>244843</ucitelid><uciteljmeno>D. Navrátil</uciteljmeno></ucitel></ucitele></slot></radek></den>
</tabulka></rozvrh>
''';