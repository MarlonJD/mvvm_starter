import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";

/// Opens the application Drift database for the current Flutter platform.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(
    name: "radlofa_app",
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse("sqlite3.wasm"),
      driftWorker: Uri.parse("drift_worker.js"),
    ),
  );
}
