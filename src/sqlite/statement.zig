const std = @import("std");
const c = @import("c.zig");

pub const Row = c.Row;

allocator: std.mem.Allocator,
handle: *c.sqlite3_stmt,

pub fn finalize(self: *@This()) void {
    var status = c.sqlite3_finalize(self.handle);
    switch (@intToEnum(c.Status, status)) {
        .ok => {},
        inline else => |error_status| @panic(@tagName(error_status)),
    }
}

pub fn free_row(self: *@This(), row: *Row) void {
    for (row.*) |column| switch (column) {
        .int, .float, .null => {},
        inline .text, .blob => |value| self.allocator.free(value),
    };
    self.allocator.free(row.*);
}

pub fn step(self: *@This()) !?Row {
    var status = c.sqlite3_step(self.handle);
    return switch (@intToEnum(c.Status, status)) {
        .row => self.handle_row(),
        .done => null,
        else => |error_status| c.status_to_error(error_status),
    };
}

pub fn bind(self: *@This(), comptime bindings: anytype) !void {
    const ArgsType = @TypeOf(bindings);
    const args_type_info = @typeInfo(ArgsType);
    if (args_type_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
    }
    const fields_info = args_type_info.Struct.fields;
    if (fields_info.len > 2000) { // SQLITE_MAX_COLUMN
        @compileError("2000 arguments max are supported per bind call");
    }
    const param_count = c.sqlite3_bind_parameter_count(self.handle);
    if (fields_info.len != @intCast(usize, param_count)) @panic("Invalid argument length");

    inline for (fields_info, 1..) |info, i| {
        var status: c_int = undefined;
        switch (@typeInfo(info.type)) {
            .Pointer => |ptr| if (ptr.sentinel) |_| {
                status = c.sqlite3_bind_text(self.handle, i, @field(bindings, info.name), @field(bindings, info.name).len, null);
            } else {
                status = c.sqlite3_bind_blob(self.handle, i, @field(bindings, info.name), @field(bindings, info.name).len, null);
            },
            inline .Int, .ComptimeInt => {
                status = c.sqlite3_bind_int(self.handle, i, @field(bindings, info.name));
            },
            inline .Float, .ComptimeFloat => {
                status = c.sqlite3_bind_double(self.handle, i, @field(bindings, info.name));
            },
            inline else => @compileError("Invalid type for bind " ++ @typeName(info.type) ++ " (" ++ @tagName(@typeInfo(info.type)) ++ ")"),
        }

        switch (@intToEnum(c.Status, status)) {
            .ok => {},
            else => |error_status| return c.status_to_error(error_status),
        }
    }
}

fn handle_row(self: *@This()) !?Row {
    var count = c.sqlite3_data_count(self.handle);
    var row = try std.ArrayList(c.Column).initCapacity(self.allocator, @intCast(usize, count));
    defer row.deinit();

    for (0..@intCast(usize, count)) |i| {
        var column_type = c.sqlite3_column_type(self.handle, @intCast(c_int, i));
        switch (@intToEnum(c.ColumnType, column_type)) {
            .int => try row.append(.{ .int = c.sqlite3_column_int64(self.handle, @intCast(c_int, i)) }),
            .float => try row.append(.{ .float = c.sqlite3_column_double(self.handle, @intCast(c_int, i)) }),
            .text => {
                var bytes = c.sqlite3_column_bytes(self.handle, @intCast(c_int, i));
                var text = c.sqlite3_column_text(self.handle, @intCast(c_int, i));
                var text_copy = try self.allocator.dupeZ(u8, text[0..@intCast(usize, bytes)]);
                try row.append(.{ .text = text_copy });
            },
            .blob => {
                var bytes = c.sqlite3_column_bytes(self.handle, @intCast(c_int, i));
                var blob = c.sqlite3_column_blob(self.handle, @intCast(c_int, i));
                var blob_copy = try self.allocator.dupe(u8, @ptrCast([*c]u8, @constCast(blob.?))[0..@intCast(usize, bytes)]);
                try row.append(.{ .blob = blob_copy });
            },
            .null => try row.append(.{ .null = null }),
        }
    }
    return try row.toOwnedSlice();
}
