/// How a column travels between SQLite and the server.
enum SyncColumnKind {
  text,
  integer,

  /// 0/1 in SQLite, boolean on the server.
  boolean,

  /// Seconds since the epoch in SQLite (Drift's default), ISO 8601 UTC on the
  /// server.
  timestamp,
}

class SyncColumn {
  const SyncColumn(this.name, this.kind);

  final String name;
  final SyncColumnKind kind;
}

/// A table that syncs, and which of its columns go to the server. Columns
/// not listed (a transaction's `scan_record_id`, `attachment_path`) stay on
/// the device and are never overwritten by a pull.
class SyncTable {
  const SyncTable(this.name, this.columns);

  final String name;
  final List<SyncColumn> columns;
}

const _t = SyncColumnKind.text;
const _i = SyncColumnKind.integer;
const _b = SyncColumnKind.boolean;
const _d = SyncColumnKind.timestamp;

/// In dependency order: a transaction needs its account and category first.
const syncTables = <SyncTable>[
  SyncTable('accounts', [
    SyncColumn('id', _t),
    SyncColumn('name', _t),
    SyncColumn('kind', _t),
    SyncColumn('currency_code', _t),
    SyncColumn('opening_balance_minor', _i),
    SyncColumn('last_four', _t),
    SyncColumn('is_archived', _b),
    SyncColumn('created_at', _d),
    SyncColumn('updated_at', _d),
  ]),
  SyncTable('categories', [
    SyncColumn('id', _t),
    SyncColumn('name', _t),
    SyncColumn('kind', _t),
    SyncColumn('icon_key', _t),
    SyncColumn('color_value', _i),
    SyncColumn('is_default', _b),
    SyncColumn('is_archived', _b),
    SyncColumn('created_at', _d),
    SyncColumn('updated_at', _d),
  ]),
  SyncTable('transactions', [
    SyncColumn('id', _t),
    SyncColumn('type', _t),
    SyncColumn('amount_minor', _i),
    SyncColumn('currency_code', _t),
    SyncColumn('account_id', _t),
    SyncColumn('destination_account_id', _t),
    SyncColumn('category_id', _t),
    SyncColumn('merchant', _t),
    SyncColumn('note', _t),
    SyncColumn('occurred_at', _d),
    SyncColumn('source', _t),
    SyncColumn('provider_reference', _t),
    SyncColumn('created_at', _d),
    SyncColumn('updated_at', _d),
  ]),
];

SyncTable syncTableNamed(String name) =>
    syncTables.firstWhere((t) => t.name == name);
