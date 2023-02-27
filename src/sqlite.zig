const std = @import("std");

pub const sqlite = @This();
const c = @import("sqlite/c.zig");
pub const Error = c.Error;
pub const Status = c.Status;
pub const DbConfig = @import("sqlite/db_config.zig");
pub const Statement = @import("sqlite/statement.zig");
pub const Record = @import("sqlite/record.zig").Record;

allocator: std.mem.Allocator,
handle: *c.sqlite3,

pub fn open(allocator: std.mem.Allocator, filename: []const u8, flags: ?c_int, vfs: ?[]const u8) !@This() {
    var handle: ?*c.sqlite3 = null;
    errdefer _ = c.sqlite3_close(handle);

    var filename_for_sqlite = try allocator.dupeZ(u8, filename);
    defer allocator.free(filename_for_sqlite);

    var status: c_int = undefined;
    if (vfs) |name| {
        var name_for_sqlite = try allocator.dupeZ(u8, name);
        defer allocator.free(name_for_sqlite);
        status = c.sqlite3_open_v2(filename_for_sqlite, &handle, flags orelse 0, name_for_sqlite);
    } else {
        status = c.sqlite3_open(filename_for_sqlite, &handle);
    }

    return switch (@intToEnum(Status, status)) {
        .ok => .{ .allocator = allocator, .handle = handle.? },
        else => |error_status| c.status_to_error(error_status),
    };
}

pub fn close(self: *@This()) void {
    var status = c.sqlite3_close(self.handle);
    switch (@intToEnum(Status, status)) {
        .ok => {},
        inline else => |error_status| @panic(@tagName(error_status)),
    }
}

pub fn db_config(self: *@This(), config: DbConfig.Config) !void {
    var status = switch (config) {
        .enable_fkey, .enable_trigger, .enable_fts3_tokenizer, .enable_load_extension, .no_ckpt_on_close, .enable_qpsg, .trigger_eqp, .defensive, .writable_schema, .legacy_alter_table, .dqs_dml, .dqs_ddl, .legacy_file_format, .trusted_schema => |op| switch (op) {
            .read => |read| c.sqlite3_db_config(self.handle, @enumToInt(config), @as(c_int, -1), @ptrCast(*allowzero const anyopaque, read)),
            .write => |write| if (write) c.sqlite3_db_config(self.handle, @enumToInt(config), @as(c_int, 1), @as(c_int, 0)) else c.sqlite3_db_config(self.handle, @enumToInt(config), @as(c_int, 0), @as(c_int, 0)),
        },
        .maindbname => |op| c.sqlite3_db_config(self.handle, @enumToInt(config), @ptrCast(*allowzero const anyopaque, op)),
        .lookaside => |op| c.sqlite3_db_config(self.handle, @enumToInt(config), op),
        .reset_database => |op| switch (op) {
            .step1 => c.sqlite3_db_config(self.handle, @enumToInt(config), @as(c_int, 1), @as(c_int, 0)),
            .step2 => c.sqlite3_db_config(self.handle, @enumToInt(config), @as(c_int, 0), @as(c_int, 1)),
        },
    };
    switch (@intToEnum(Status, status)) {
        .ok => {},
        else => |error_status| return c.status_to_error(error_status),
    }
}

pub fn prepare(self: *@This(), zSql: []const u8, flags: ?[]c.PrepareFlags) !Statement {
    var stmt: ?*c.sqlite3_stmt = null;
    errdefer _ = c.sqlite3_finalize(stmt);

    var zSql_for_sqlite = try self.allocator.dupeZ(u8, zSql);
    defer self.allocator.free(zSql_for_sqlite);

    var status: c_int = undefined;
    if (flags) |f| {
        var flags_for_sqlite: c_uint = 0;
        for (f) |flag_for_sqlite| {
            flags_for_sqlite |= @enumToInt(flag_for_sqlite);
        }
        status = c.sqlite3_prepare_v3(self.handle, zSql_for_sqlite.ptr, @intCast(c_int, zSql_for_sqlite.len), flags_for_sqlite, &stmt, null);
    } else {
        status = c.sqlite3_prepare_v2(self.handle, zSql_for_sqlite.ptr, @intCast(c_int, zSql_for_sqlite.len), &stmt, null);
    }

    return switch (@intToEnum(Status, status)) {
        .ok => .{ .allocator = self.allocator, .handle = stmt.? },
        else => |error_status| c.status_to_error(error_status),
    };
}

test {
    var db = try sqlite.open(std.testing.allocator, ":memory:", null, null);
    defer db.close();

    try db.db_config(.{ .enable_load_extension = .{ .write = true } });
    var enabled: c_int = undefined;
    try db.db_config(.{ .enable_load_extension = .{ .read = &enabled } });
    try std.testing.expectEqual(enabled, 1);

    var query_stmt = try db.prepare(
        \\SELECT 'string value', 69, 69.420, x'deadbeef';
    , null);
    defer query_stmt.finalize();

    var query_result = try query_stmt.step() orelse return error.NoResults;
    defer query_stmt.free_row(&query_result);

    try std.testing.expectFmt("string value", "{s}", .{query_result[0].text});
    try std.testing.expectEqual(@as(i64, 69), query_result[1].int);
    try std.testing.expectEqual(@as(f64, 69.420), query_result[2].float);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xde, 0xad, 0xbe, 0xef }, query_result[3].blob);

    var create_table_stmt = try db.prepare(
        \\CREATE TABLE my_table(value_text TEXT, value_int INTEGER, value_real REAL, value_blob BLOB);"
    , null);
    defer create_table_stmt.finalize();

    const create_table_done = create_table_stmt.step();
    try std.testing.expectEqual(create_table_done, null);

    var insert_stmt = try db.prepare(
        \\INSERT INTO my_table(value_text, value_int, value_real, value_blob) VALUES (?1, ?2, ?3, ?4);
    , null);
    defer insert_stmt.finalize();

    const text: [:0]const u8 = "hello, world";
    try insert_stmt.bind(.{ text, 69, 69.420, &[_]u8{ 0xde, 0xad, 0xbe, 0xef } });
    const insert_done = insert_stmt.step();
    try std.testing.expectEqual(insert_done, null);

    var table_query_stmt = try db.prepare(
        \\SELECT * from my_table;
    , null);
    defer table_query_stmt.finalize();

    var table_query_result = try table_query_stmt.step() orelse return error.NoResults;
    defer table_query_stmt.free_row(&table_query_result);

    try std.testing.expectFmt("hello, world", "{s}", .{table_query_result[0].text});
    try std.testing.expectEqual(@as(i64, 69), table_query_result[1].int);
    try std.testing.expectEqual(@as(f64, 69.420), table_query_result[2].float);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xde, 0xad, 0xbe, 0xef }, table_query_result[3].blob);

    const MyTableSchema = struct { value_text: [:0]const u8, value_int: i64, value_real: f64, value_blob: []const u8 };
    const MyTable = Record(MyTableSchema);
    var my_table_fetchall = MyTable.init(&db);
    defer my_table_fetchall.deinit();

    try my_table_fetchall.prepare("SELECT * from my_table;");
    var records = try my_table_fetchall.fetchall();
    defer my_table_fetchall.freeall(&records);

    try std.testing.expectEqual(records.len, 1);
    try std.testing.expectFmt("hello, world", "{s}", .{records[0].value_text});
    try std.testing.expectEqual(@as(i64, 69), records[0].value_int);
    try std.testing.expectEqual(@as(f64, 69.420), records[0].value_real);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xde, 0xad, 0xbe, 0xef }, records[0].value_blob);

    var my_table_insertone = MyTable.init(&db);
    defer my_table_insertone.deinit();

    try my_table_insertone.prepare("INSERT INTO my_table(value_text, value_int, value_real, value_blob) VALUES(?,?,?,?);");
    const my_table_insertone_text: [:0]const u8 = "foo bar";

    try my_table_insertone.insert(.{ my_table_insertone_text, 420, 420.69, &[_]u8{ 0xfe, 0xed } });

    var my_table_fetchone = MyTable.init(&db);
    defer my_table_fetchone.deinit();

    try my_table_fetchone.prepare("SELECT * FROM my_table WHERE value_text = ?;");

    var my_table_fetchone_record = try my_table_fetchone.fetchone(.{my_table_insertone_text});
    defer my_table_insertone.freeone(&my_table_fetchone_record);

    try std.testing.expectFmt("foo bar", "{s}", .{my_table_fetchone_record.value_text});
    try std.testing.expectEqual(@as(i64, 420), my_table_fetchone_record.value_int);
    try std.testing.expectEqual(@as(f64, 420.69), my_table_fetchone_record.value_real);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xfe, 0xed }, my_table_fetchone_record.value_blob);
}
