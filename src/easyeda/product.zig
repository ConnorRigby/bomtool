const std = @import("std");
const json = std.json;

pub const List = @import("product/list.zig");
const Tree = @import("catalog/tree.zig");
const Component = @import("component.zig");

const Http = @import("../http.zig");

pub const Price = enum {
    quantity,
    price,
};

ifRoHS: ?bool = null,
price: ?[][]union(Price) {
    quantity: usize,
    price: ?[]const u8,
} = null,
stock: ?usize = null,
mpn: ?[]const u8 = null,
number: ?[]const u8 = null,
package: ?[]const u8 = null,
manufacturer: ?[]const u8 = null,
url: ?[]const u8 = null,
image: ?[]struct {
    sort: ?usize = null,
    type: ?[]const u8 = null,
    @"900x900": ?[]const u8 = null,
    @"224x22": ?[]const u8 = null,
    @"96x96": ?[]const u8 = null,
} = null,
mfrLink: ?[]const u8 = null,
component: ?Component = null,

pub fn list(client: *Http, catalog: *const Tree.Result) !List {
    const url: [:0]const u8 = try std.fmt.allocPrintZ(client.allocator, "https://easyeda.com/api/eda/product/list?version=6.5.22&catalog={d}", .{catalog.catalogId.?});
    defer client.allocator.free(url);

    var response = try client.perform(url);

    var token_stream = json.TokenStream.init(response.body);
    var options: json.ParseOptions = .{ .allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false };
    @setEvalBranchQuota(5000);
    var parsed = try json.parse(List, &token_stream, options);
    errdefer json.parseFree(List, parsed, options);
    return parsed;
}
