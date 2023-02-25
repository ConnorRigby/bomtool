const std = @import("std");
const Uri = std.Uri;
const Http = @import("http.zig");

const symbol = @import("symbol.zig");
const library = @import("library.zig");
const easyeda = @import("easyeda.zig");

fn search_recurse(
    http: *Http,
    query_string: []const u8,
    id: []const u8,
    symbols: *std.ArrayList(symbol.ProductSymbol),
    page: ?usize,
) !void {
    const search = try easyeda.search(http, query_string, page);
    defer easyeda.free(http, search);

    var need_next_page = false;
    if (search.find_product_by_number(id)) |product| {
        std.log.info("found product: {s}", .{id});
        try symbols.append(try symbol.from_product(http.allocator, &product));
    } else {
        std.log.info("product {s} not found on this page (size={d})", .{ id, search.result.?.productList.?.len });
        need_next_page = true;
    }

    if (need_next_page) return try search_recurse(http, query_string, id, symbols, (page orelse 1) + 1);
}

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

    var ids = std.ArrayList([]const u8).init(allocator);
    defer ids.deinit();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |id| {
        try ids.append(id);
    }

    var symbols = std.ArrayList(symbol.ProductSymbol).init(allocator);
    defer symbols.deinit();

    for (ids.items) |id| {
        // var query = try std.mem.join(allocator, " ", ids.items);
        // defer allocator.free(query);

        const query_string = try std.Uri.escapeString(allocator, id);
        defer allocator.free(query_string);
        try search_recurse(&http, query_string, id, &symbols, null);
    }

    // defer allocator.free(resistor);
    const lib = try library.render(allocator, symbols.items);
    defer allocator.free(lib);

    try stdout.print("{s}", .{lib});

    try bw.flush();
}

// fn getCatalogManus() {
//     var tree = try easyeda.catalog.tree(&http);
//     defer easyeda.free(&http, tree);
//
//     const catalog = tree.find_catalog_by_name("resistors").?;
//
//     var list = try easyeda.product.list(&http, &catalog);
//
//     var manus = try list.manufacturers(allocator);
//     defer allocator.free(manus);

//     var manu_buffer = std.ArrayList(u8).init(allocator);
//     defer manu_buffer.deinit();

//     try manu_buffer.appendSlice("pub const Manufacturer = enum(usize) {\n");
//     for(manus) |manu| {
//         const line = try std.fmt.allocPrint(allocator, "@\"{s}\" = {d},", .{
//             manu.name,
//             manu.id
//         });
//         defer allocator.free(line);
//         try manu_buffer.appendSlice(line);
//     }

//     var source = try manu_buffer.toOwnedSliceSentinel(0);

//     var ast = try std.zig.parse(allocator, source);
//     defer ast.deinit(allocator);
//     var formatted = try ast.render(allocator);
//     defer allocator.free(formatted);
// }

test {
    std.testing.refAllDecls(symbol);
    // std.testing.refAllDecls(easyeda);
}
