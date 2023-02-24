const std = @import("std");
const ascii = std.ascii;

pub const Result = struct {
    catalogId: ?usize,
    parentId: ?usize,
    parentName: ?[]const u8,
    catalogName: ?[]const u8,
    productNum: ?usize,
    sonList: ?[]struct {
        catalogId: ?usize,
        catalogName: ?[]const u8,
        parentId: ?usize,
    },
};

code: ?usize,
msg: ?[]const u8,
result: ?[]Result,

pub fn find_catalog_by_name(self: *const @This(), find: []const u8) ?Result {
    var found: ?Result = null;
    if (self.result) |result| {
        for (result) |item| {
            if (item.catalogName) |name| if (ascii.eqlIgnoreCase(name, find)) {
                found = item;
                break;
            };
        }
    }
    return found;
}
