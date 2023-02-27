const std = @import("std");
const Uri = std.Uri;
const Http = @import("http.zig");

const symbol = @import("symbol.zig");
const library = @import("library.zig");
const easyeda = @import("easyeda.zig");

const sqlite = @import("sqlite.zig");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var http = try Http.init(allocator);
    defer http.deinit();

    var db = try sqlite.open(std.heap.c_allocator, "database.db", null, null);
    defer db.deinit();

    std.debug.print("db={any}\n", .{db});

    // var tree = try easyeda.catalog.tree(&http);
    // defer easyeda.free(&http, tree);

    // for(tree.result.?) |catalog| {

    // }

    try stdout.print("hello, world", .{});

    try bw.flush();
}
