const std = @import("std");

const Product = @import("product.zig");
const Param = @import("param.zig");

pub const Result = struct {
    total: ?usize = null,
    paramList: ?[]Param = null,
    productList: ?[]Product = null,
};

code: ?usize = null,
msg: ?[]const u8 = null,
result: ?Result = null,

pub fn find_product_by_number(self: *const @This(), id: []const u8) ?Product {
    for (self.result.?.productList.?) |product|
        if (product.number) |number|
            if (std.ascii.eqlIgnoreCase(number, id))
                return product;
    return null;
}
