import 'dart:io';

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run this from the frontend directory.');
    exit(1);
  }

  final issues = <String>[];
  final textLiteral = RegExp(
    r'''\bText\(\s*(['"])(?!\$)(?:(?!\1).)*[\u0600-\u06FFA-Za-z]{2,}(?:(?!\1).)*\1''',
    dotAll: true,
  );

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    final matches = textLiteral.allMatches(content).length;
    if (matches > 0) {
      issues.add('${entity.path}: $matches possible hardcoded Text literals');
    }
  }

  if (issues.isNotEmpty) {
    stdout.writeln('i18n hardcoded-string scan warnings:');
    for (final issue in issues) {
      stdout.writeln('- $issue');
    }
    stdout.writeln('Use context.tr(key) or AppLocalizations keys for every user-facing string.');
    return;
  }

  stdout.writeln('i18n hardcoded-string scan passed.');
}
