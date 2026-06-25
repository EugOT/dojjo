import 'dart:io';

import 'package:dojjo/src/commands/completion_command.dart';
import 'package:test/test.dart';

/// Runs dojjo's bash completion function for [words] (the full `COMP_WORDS`,
/// with the last entry being the word under the cursor) inside [workingDir],
/// returning the produced `COMPREPLY` entries.
List<String> bashComplete(List<String> words, String workingDir) {
  final scriptFile = File('$workingDir/_djo.bash')..writeAsStringSync(_bashScript);
  final wordList = words.map((w) => '"$w"').join(' ');
  final driver =
      '''
source '${scriptFile.path}'
COMP_WORDS=($wordList)
COMP_CWORD=${words.length - 1}
COMPREPLY=()
_djo_complete
printf '%s\\n' "\${COMPREPLY[@]}"
''';
  final result = Process.runSync('bash', ['-c', driver], workingDirectory: workingDir);
  if (result.exitCode != 0) {
    fail('bash completion driver failed (${result.exitCode}): ${result.stderr}');
  }
  return (result.stdout as String).split('\n').where((line) => line.isNotEmpty).toList();
}

final _bashScript = completionScript('bash') ?? (throw StateError('no bash completion script'));

void main() {
  group('completionScript', () {
    test('returns a script for each supported shell', () {
      for (final shell in ['bash', 'zsh', 'fish', 'pwsh', 'powershell']) {
        expect(completionScript(shell), isNotNull, reason: shell);
      }
    });

    test('returns null for an unsupported shell', () {
      expect(completionScript('ksh'), isNull);
    });
  });

  group('bash completion (functional)', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('djo_completion_');
      File('${dir.path}/alpha.rc').writeAsStringSync('');
      File('${dir.path}/beta.rc').writeAsStringSync('');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('`shell install <shell> [path]` completes files', () {
      final candidates = bashComplete(['djo', 'shell', 'install', 'bash', ''], dir.path);
      expect(candidates, containsAll(['alpha.rc', 'beta.rc']));
    });

    test('`shell install` path completion respects the typed prefix', () {
      final candidates = bashComplete(['djo', 'shell', 'install', 'bash', 'al'], dir.path);
      expect(candidates, equals(['alpha.rc']));
    });

    test('`shell <TAB>` still completes subcommands, not files', () {
      final candidates = bashComplete(['djo', 'shell', ''], dir.path);
      expect(candidates, equals(['completion', 'init', 'install']));
    });
  });

  group('install-path file completion is wired for every shell', () {
    test('zsh uses _files for the install path', () {
      final zsh = completionScript('zsh');
      expect(zsh, contains('_files'));
    });

    test('fish forces file completion when install is seen', () {
      final fish = completionScript('fish');
      expect(fish, contains("__fish_seen_subcommand_from install' -F"));
    });

    test('powershell lists filesystem entries for the install path', () {
      final pwsh = completionScript('pwsh');
      expect(pwsh, contains('Get-ChildItem'));
    });
  });
}
