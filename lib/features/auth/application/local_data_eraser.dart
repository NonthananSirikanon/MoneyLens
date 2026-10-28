import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../infrastructure/database/user_database_files.dart';
import '../../slip_import/application/slip_import_providers.dart';
import '../../slip_import/domain/import_ports.dart';

/// Removes what an account left on this device after the account itself has
/// been deleted on the server.
abstract interface class LocalDataEraser {
  /// Deletes the slip image files in [slipPaths] and [userId]'s database.
  /// Never throws: the account is already gone, so a leftover file must not
  /// turn a successful deletion into an error.
  Future<void> erase({required String userId, required List<String> slipPaths});
}

class DeviceDataEraser implements LocalDataEraser {
  const DeviceDataEraser(this._slips);

  final SlipImageStore _slips;

  @override
  Future<void> erase({
    required String userId,
    required List<String> slipPaths,
  }) async {
    for (final path in slipPaths) {
      try {
        await _slips.delete(path);
      } on Object {
        // Keep going: erase as much as possible.
      }
    }
    try {
      await UserDatabaseFiles.deleteFor(
        await getApplicationDocumentsDirectory(),
        userId,
      );
    } on Object {
      // See above.
    }
  }
}

final localDataEraserProvider = Provider<LocalDataEraser>(
  (ref) => DeviceDataEraser(ref.watch(slipImageStoreProvider)),
);
