const std = @import("std");
const json = std.json;

pub const Tree = @import("catalog/tree.zig");

const Http = @import("../http.zig");

pub fn tree(client: *Http) !Tree {
    const url: [:0]const u8 = "https://easyeda.com/api/eda/catalog/tree";
    var response = try client.perform(url);

    var token_stream = json.TokenStream.init(response.body);
    var options: json.ParseOptions = .{ .allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false };
    var parsed = try json.parse(Tree, &token_stream, options);
    errdefer json.parseFree(Tree, parsed, options);

    return parsed;
}
