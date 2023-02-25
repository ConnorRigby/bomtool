const std = @import("std");
const json = std.json;

const Http = @import("http.zig");

pub const Search = @import("easyeda/search.zig");

pub const catalog = @import("easyeda/catalog.zig");
pub const Product = @import("easyeda/product.zig");

pub fn free(client: *Http, value: anytype) void {
    var options: json.ParseOptions = .{ .allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false };
    std.json.parseFree(@TypeOf(value), value, options);
}

pub fn search(client: *Http, keyword: []const u8, page: ?usize) !Search {
    const base = "https://easyeda.com/api/eda/product/search?version=6.5.22&keyword={s}&needComponents=true&needAggs=true&pageSize=10";
    const url: [:0]const u8 = if (page) |p| try std.fmt.allocPrintZ(client.allocator, base ++ "?&currPage={d}", .{ keyword, p }) else try std.fmt.allocPrintZ(client.allocator, base, .{keyword});
    defer client.allocator.free(url);

    var response = try client.perform(url);

    var token_stream = json.TokenStream.init(response.body);
    var options: json.ParseOptions = .{ .allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false };
    @setEvalBranchQuota(5000);
    var parsed = try json.parse(Search, &token_stream, options);
    errdefer json.parseFree(Search, parsed, options);
    return parsed;
}
