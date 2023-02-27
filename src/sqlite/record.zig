const std = @import("std");
const sqlite = @import("../sqlite.zig");
const Statement = @import("statement.zig");
const c = @import("c.zig");

pub fn Record(comptime T: type) type {
    return struct {
        const Self = @This();

        stmt: ?Statement = null,
        db: *sqlite,

        pub fn init(db: *sqlite) Self {
            return .{ .db = db };
        }

        pub fn deinit(self: *Self) void {
            if (self.stmt) |_| {
                self.stmt.?.finalize();
            }
        }

        pub fn prepare(self: *Self, zSql: []const u8) !void {
            if (self.stmt) |_| return error.AlreadyPrepared;
            var stmt = try self.db.prepare(zSql, null);
            self.stmt = stmt;
        }

        pub fn fetchall(self: *Self) ![]T {
            if (self.stmt) |_| {
                var result = std.ArrayList(T).init(self.db.allocator);
                defer result.deinit();

                while (try self.stmt.?.step()) |row| {
                    try result.append(try self.into_record(row));
                    // self.stmt.free_row(row);
                    self.db.allocator.free(row);
                }

                return result.toOwnedSlice();
            } else return error.NotPrepared;
        }

        pub fn freeall(self: *Self, records: *[]T) void {
            for (records.*) |record| {
                const args_type_info = @typeInfo(T);
                const fields_info = args_type_info.Struct.fields;
                inline for (fields_info) |info| switch (@typeInfo(info.type)) {
                    .Pointer => self.db.allocator.free(@field(record, info.name)),
                    inline else => {},
                };
            }
            self.db.allocator.free(records.*);
        }

        pub fn fetchone(self: *Self, comptime bindings: anytype) !T {
            if (self.stmt) |_| {
                try self.stmt.?.bind(bindings);
                var result: T = undefined;

                if (try self.stmt.?.step()) |row| {
                    result = try self.into_record(row);
                    self.db.allocator.free(row);
                } else return error.NoResults;

                return result;
            } else return error.NotPrepared;
        }

        pub fn freeone(self: *Self, record: *T) void {
            const args_type_info = @typeInfo(T);
            const fields_info = args_type_info.Struct.fields;
            inline for (fields_info) |info| switch (@typeInfo(info.type)) {
                .Pointer => self.db.allocator.free(@field(record, info.name)),
                inline else => {},
            };
        }

        pub fn insert(self: *Self, comptime bindings: anytype) !void {
            try self.stmt.?.bind(bindings);
            if (try self.stmt.?.step()) |_| @panic("insert returned data");
        }

        fn into_record(self: *Self, row: Statement.Row) !T {
            const args_type_info = @typeInfo(T);
            const fields_info = args_type_info.Struct.fields;
            var result: T = undefined;
            inline for (fields_info) |info| {
                for (row, 0..) |column, i| {
                    var column_name_from_sqlite = c.sqlite3_column_name(self.stmt.?.handle, @intCast(c_int, i));
                    var column_name = std.mem.span(column_name_from_sqlite);
                    if (std.mem.eql(u8, column_name, info.name)) switch (@typeInfo(info.type)) {
                        inline .Int, .ComptimeInt => @field(result, info.name) = column.int,
                        inline .Float, .ComptimeFloat => @field(result, info.name) = column.float,
                        inline .Pointer => comptime {
                            if (@typeInfo(info.type).Pointer.sentinel) |_| {
                                @field(result, info.name) = column.text;
                            } else @field(result, info.name) = column.blob;
                        },
                        inline else => @panic("Invalid type"),
                    };
                }
            }
            return result;
        }
    };
}
