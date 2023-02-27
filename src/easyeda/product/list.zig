const std = @import("std");
const ascii = std.ascii;

const Product = @import("../product.zig");
const Param = @import("../param.zig");

pub const Result = struct {
    total: ?usize = null,
    paramList: ?[]Param = null,
    productList: ?[]Product = null,
};

code: ?usize = null,
msg: ?[]const u8 = null,
result: ?Result = null,

pub const Manufacturer = struct { id: usize, name: []const u8 };

pub fn manufacturers(self: *const @This(), allocator: std.mem.Allocator) ![]Manufacturer {
    var param = self.find_param("manufacturer") orelse return error.ParamNotFound;
    var id_list = param.parameterIdList orelse return error.ParamIdListNotFound;
    var value_list = param.parameterValueList orelse return error.ParamIdListNotFound;
    if (id_list.len != value_list.len) return error.ParamIdListInvalid;

    var list = try std.ArrayList(Manufacturer).initCapacity(allocator, id_list.len);
    errdefer list.deinit();

    for (id_list, 0..) |id, index| try list.append(.{ .id = id, .name = value_list[index] });
    return list.toOwnedSlice();
}

pub fn find_param(self: *const @This(), param: []const u8) ?Param {
    if (self.result) |result|
        if (result.paramList) |list|
            for (list) |item|
                if (item.parameterName) |name|
                    if (ascii.eqlIgnoreCase(name, param))
                        return item;

    return null;
}
