// Throwaway harness: parses the sample GMet bulletin and prints what the
// importer would put into the table. Run with:
//   dart run tool/check_bulletin_parse.dart "EVENING FORECAST 11072026.pdf"
import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:weather_admin_dashboard/app/services/cafo_pdf_import_service.dart';

Future<void> main(List<String> args) async {
  await pdfrxInitialize();

  final path = args.isEmpty ? 'EVENING FORECAST 11072026.pdf' : args.first;
  final bytes = await File(path).readAsBytes();

  final b = await parseCafoBulletin(bytes);

  stdout.writeln('issueTime     : ${b.issueTime}');
  stdout.writeln('periodHeaders : ${b.periodHeaders}');
  stdout.writeln('warnings      : ${b.warnings}');
  stdout.writeln('summary       : ${b.summary}');
  stdout.writeln('rows          : ${b.rows.length}');
  stdout.writeln('');
  stdout.writeln(
    '${'CITY'.padRight(16)}'
    '${'SLOT1'.padRight(22)}'
    '${'SLOT2'.padRight(22)}'
    'SLOT3',
  );
  for (final r in b.rows) {
    final cells = r.slots
        .map((s) => '${s.weather}/${s.prob}/${s.temp}'.padRight(22))
        .join();
    stdout.writeln('${r.cityName.padRight(16)}$cells');
  }
}
