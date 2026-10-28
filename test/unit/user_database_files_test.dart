import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/infrastructure/database/user_database_files.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('ml_db_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File legacy(String suffix, String text) =>
      File(p.join(dir.path, 'moneylens.sqlite$suffix'))
        ..writeAsStringSync(text);

  test('each user gets a separate file', () async {
    final a = await UserDatabaseFiles.resolve(dir, 'user-a');
    final b = await UserDatabaseFiles.resolve(dir, 'user-b');
    expect(a.path, isNot(b.path));
    expect(p.basename(a.path), 'moneylens_user-a.sqlite');
  });

  test('ids that are not file-name safe cannot escape the folder', () async {
    final f = await UserDatabaseFiles.resolve(dir, '../../etc/passwd');
    expect(p.dirname(f.path), dir.path);
    expect(p.basename(f.path), 'moneylens_______etc_passwd.sqlite');
  });

  test(
    'the first user takes over the shared file, with its side files',
    () async {
      legacy('', 'main');
      legacy('-wal', 'wal');
      legacy('-shm', 'shm');

      final a = await UserDatabaseFiles.resolve(dir, 'user-a');
      expect(a.readAsStringSync(), 'main');
      expect(File('${a.path}-wal').readAsStringSync(), 'wal');
      expect(File('${a.path}-shm').readAsStringSync(), 'shm');
      expect(UserDatabaseFiles.legacyFile(dir).existsSync(), isFalse);
    },
  );

  test('a second user does not get the first user\'s data', () async {
    legacy('', 'main');
    final a = await UserDatabaseFiles.resolve(dir, 'user-a');
    final b = await UserDatabaseFiles.resolve(dir, 'user-b');
    expect(a.readAsStringSync(), 'main');
    expect(b.existsSync(), isFalse);
  });

  test(
    'a user who already has a file keeps it and leaves the shared one',
    () async {
      final a = UserDatabaseFiles.userFile(dir, 'user-a')
        ..writeAsStringSync('mine');
      legacy('', 'old');
      final resolved = await UserDatabaseFiles.resolve(dir, 'user-a');
      expect(resolved.readAsStringSync(), 'mine');
      expect(a.path, resolved.path);
      expect(UserDatabaseFiles.legacyFile(dir).existsSync(), isTrue);
    },
  );
}
