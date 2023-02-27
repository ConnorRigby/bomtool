const c = @import("c.zig");

pub const Op = enum(c_int) {
    maindbname = c.SQLITE_DBCONFIG_MAINDBNAME,
    lookaside = c.SQLITE_DBCONFIG_LOOKASIDE,
    enable_fkey = c.SQLITE_DBCONFIG_ENABLE_FKEY,
    enable_trigger = c.SQLITE_DBCONFIG_ENABLE_TRIGGER,
    enable_fts3_tokenizer = c.SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER,
    enable_load_extension = c.SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION,
    no_ckpt_on_close = c.SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE,
    enable_qpsg = c.SQLITE_DBCONFIG_ENABLE_QPSG,
    trigger_eqp = c.SQLITE_DBCONFIG_TRIGGER_EQP,
    reset_database = c.SQLITE_DBCONFIG_RESET_DATABASE,
    defensive = c.SQLITE_DBCONFIG_DEFENSIVE,
    writable_schema = c.SQLITE_DBCONFIG_WRITABLE_SCHEMA,
    legacy_alter_table = c.SQLITE_DBCONFIG_LEGACY_ALTER_TABLE,
    dqs_dml = c.SQLITE_DBCONFIG_DQS_DML,
    dqs_ddl = c.SQLITE_DBCONFIG_DQS_DDL,
    // enable_view = c.SQLITE_DBCONFIG_ENABLE_VIEW,
    legacy_file_format = c.SQLITE_DBCONFIG_LEGACY_FILE_FORMAT,
    trusted_schema = c.SQLITE_DBCONFIG_TRUSTED_SCHEMA,
    // max = c.SQLITE_DBCONFIG_MAX,
};

pub const ReadWriteOp = enum { read, write };

pub const ReadWrite = union(ReadWriteOp) {
    read: *c_int,
    write: bool,
};

pub const Config = union(Op) {
    maindbname: *const [*c]const u8,
    lookaside: *allowzero anyopaque,
    enable_fkey: ReadWrite,
    enable_trigger: ReadWrite,
    enable_fts3_tokenizer: ReadWrite,
    enable_load_extension: ReadWrite,
    no_ckpt_on_close: ReadWrite,
    enable_qpsg: ReadWrite,
    trigger_eqp: ReadWrite,
    reset_database: enum { step1, step2 },
    defensive: ReadWrite,
    writable_schema: ReadWrite,
    legacy_alter_table: ReadWrite,
    dqs_dml: ReadWrite,
    dqs_ddl: ReadWrite,
    // enable_view: @typeOf(null),
    legacy_file_format: ReadWrite,
    trusted_schema: ReadWrite,
    // max: @typeOf(null),
};
