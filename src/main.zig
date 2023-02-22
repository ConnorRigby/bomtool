const std = @import("std");
const Uri = std.Uri;
const http = std.http;

const component = @import("providers/component.zig");

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var client: http.Client = .{.allocator = allocator};

    // var uri = try Uri.parse("https://google.com/");
    // var request = try client.request(uri, .{}, .{});
    // defer request.deinit();
    // std.log.info("uri = {any}", .{uri});
    // std.log.info("request = {any}", .{request});

    // var buffer = try allocator.alloc(u8, 1024);
    // defer allocator.free(buffer);

    // var size = try request.readAll(buffer);
    // std.log.info("response[{d}] = {s}", .{size, buffer});

    try component.get(&client, "C1525");

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
