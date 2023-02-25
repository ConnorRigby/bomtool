const std = @import("std");
const fmt = std.fmt;

pub const Resistor = @import("symbols/resistor.zig");
pub const Capacitor = @import("symbols/capacitor.zig");
pub const easyeda = @import("easyeda.zig");
pub const ProductSymbolClass = enum { resistor, capacitor };

pub const ProductSymbol = union(ProductSymbolClass) { resistor: Resistor, capacitor: Capacitor };

pub fn from_product(allocator: std.mem.Allocator, product: *const easyeda.Product) !ProductSymbol {
    if (product.component.?.dataStr.?.head.?.c_para.?.Resistance) |_| return .{ .resistor = try resistor(allocator, product) };
    if (product.component.?.dataStr.?.head.?.c_para.?.Capacitance) |_| return .{ .capacitor = try capacitor(allocator, product) };
    return error.UnknownProduct;
}

pub fn alloc_common(allocator: std.mem.Allocator, product: *const easyeda.Product) !struct {
    number: []const u8,
    value: []const u8,
    description: []const u8,
    datasheet: []const u8,
    manufacturer: []const u8,
    mpn: []const u8,
} {
    const component = product.component.?;

    const number = try allocator.dupe(u8, product.number.?);
    errdefer allocator.free(number);

    const value = try allocator.dupe(u8, component.title.?);
    errdefer allocator.free(value);

    const description = try allocator.dupe(u8, component.description.?);
    errdefer allocator.free(description);

    const datasheet = try std.fmt.allocPrint(allocator, "https://www.lcsc.com{s}", .{product.url.?});
    errdefer allocator.free(datasheet);

    const manufacturer = try allocator.dupe(u8, product.manufacturer.?);
    errdefer allocator.free(manufacturer);

    const mpn = try allocator.dupe(u8, product.mpn.?);
    errdefer allocator.free(mpn);
    return .{ .number = number, .value = value, .description = description, .datasheet = datasheet, .manufacturer = manufacturer, .mpn = mpn };
}

pub fn resistor(allocator: std.mem.Allocator, product: *const easyeda.Product) !Resistor {
    const component = product.component.?;
    const resistance = try allocator.dupe(u8, component.dataStr.?.head.?.c_para.?.Resistance.?);

    const common = try alloc_common(allocator, product);
    errdefer @panic("oops! not implemented");

    const name = try std.fmt.allocPrint(allocator, "R_{s}_{s}", .{ product.package.?, resistance });
    errdefer allocator.free(name);

    const package = try Resistor.Package.parse(product.package.?);

    return Resistor{ .name = name, .value = common.value, .package = package, .resistance = resistance, .datasheet = common.datasheet, .mpn = .{ .manufacturer = common.manufacturer, .number = common.mpn }, .spn = .{ .supplier = "LCSC", .number = common.number }, .description = common.description };
}

pub fn capacitor(allocator: std.mem.Allocator, product: *const easyeda.Product) !Capacitor {
    const component = product.component.?;
    const capacitance = try allocator.dupe(u8, component.dataStr.?.head.?.c_para.?.Capacitance.?);

    const common = try alloc_common(allocator, product);
    errdefer @panic("oops! not implemented");

    const name = try std.fmt.allocPrint(allocator, "C_{s}_{s}", .{ product.package.?, capacitance });
    errdefer allocator.free(name);

    const package = try Capacitor.Package.parse(product.package.?);

    return Capacitor{ .name = name, .value = common.value, .package = package, .capacitance = capacitance, .datasheet = common.datasheet, .mpn = .{ .manufacturer = common.manufacturer, .number = common.mpn }, .spn = .{ .supplier = "LCSC", .number = common.number }, .description = common.description };
}

pub fn render(comptime T: type, symbol: *const T, allocator: std.mem.Allocator) ![]const u8 {
    return try fmt.allocPrint(allocator,
        \\  (symbol "{s}" (extends "{s}")
        \\    (property "Reference" "{s}" (id 0) (at 0.762 0.508 0)
        \\      (effects (font (size 1.27 1.27)) (justify left))
        \\    )
        \\    (property "Value" "{s}" (id 1) (at 0.762 -1.016 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Footprint" "{s}" (id 2) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Datasheet" "{s}" (id 3) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Manufacturer" "{s}" (id 4) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "MPN" "{s}" (id 5) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Supplier" "{s}" (id 6) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "SPN" "{s}" (id 7) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "{s}" "{s}" (id 8) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "{s}" "{s}" (id 9) (at 0.762 -1.016 0)
        \\      (effects (font (size 1.27 1.27)) (justify left))
        \\    )
        \\    (property "Description" "{s}" (id 10) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\  )
        \\
    , .{
        symbol.name,
        symbol.extends(),
        symbol.reference(),
        symbol.value,
        symbol.footprint(),
        symbol.datasheet,
        symbol.mpn.manufacturer,
        symbol.mpn.number,
        symbol.spn.supplier,
        symbol.spn.number,
        symbol.spn.supplier,
        symbol.spn.number,
        symbol.property(),
        symbol.property_value(),
        symbol.description,
    });
}
