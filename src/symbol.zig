const std = @import("std");
const fmt = std.fmt;

pub const Resistor = @import("symbols/resistor.zig");
pub const Capacitor = @import("symbols/capacitor.zig");
pub const Diode = @import("symbols/diode.zig");

pub const ProductSymbolClass = enum { resistor, capacitor, diode };
pub const ProductSymbol = union(ProductSymbolClass) { resistor: Resistor, capacitor: Capacitor, diode: Diode };

pub const easyeda = @import("easyeda.zig");

pub fn from_product(allocator: std.mem.Allocator, product: *const easyeda.Product) !ProductSymbol {
    if (product.component.?.dataStr.?.head.?.c_para.?.Resistance) |_| return .{ .resistor = try resistor(allocator, product) };
    if (product.component.?.dataStr.?.head.?.c_para.?.Capacitance) |_| return .{ .capacitor = try capacitor(allocator, product) };
    if (std.ascii.eqlIgnoreCase(product.component.?.dataStr.?.head.?.c_para.?.pre.?, "D?")) return .{ .diode = try diode(allocator, product) };
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

    return .{ .name = name, .value = common.value, .package = package, .resistance = resistance, .datasheet = common.datasheet, .mpn = .{ .manufacturer = common.manufacturer, .number = common.mpn }, .spn = .{ .supplier = "LCSC", .number = common.number }, .description = common.description };
}

pub fn capacitor(allocator: std.mem.Allocator, product: *const easyeda.Product) !Capacitor {
    const component = product.component.?;
    const capacitance = try allocator.dupe(u8, component.dataStr.?.head.?.c_para.?.Capacitance.?);

    const common = try alloc_common(allocator, product);
    errdefer @panic("oops! not implemented");

    const name = try std.fmt.allocPrint(allocator, "C_{s}_{s}", .{ product.package.?, capacitance });
    errdefer allocator.free(name);

    const package = try Capacitor.Package.parse(product.package.?);

    return .{ .name = name, .value = common.value, .package = package, .capacitance = capacitance, .datasheet = common.datasheet, .mpn = .{ .manufacturer = common.manufacturer, .number = common.mpn }, .spn = .{ .supplier = "LCSC", .number = common.number }, .description = common.description };
}

pub fn diode(allocator: std.mem.Allocator, product: *const easyeda.Product) !Diode {
    const common = try alloc_common(allocator, product);
    errdefer @panic("oops! not implemented");

    const name = try std.fmt.allocPrint(allocator, "D_{s}_{s}", .{ product.package.?, common.mpn });
    errdefer allocator.free(name);

    const package = try Diode.Package.parse(product.package.?);

    return .{ .name = name, .value = common.value, .package = package, .datasheet = common.datasheet, .mpn = .{ .manufacturer = common.manufacturer, .number = common.mpn }, .spn = .{ .supplier = "LCSC", .number = common.number }, .description = common.description };
}

fn render_property(allocator: std.mem.Allocator, name: []const u8, value: []const u8, id: usize, at: []const u8, justify: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(allocator,
        \\    (property "{s}" "{s}" (id {d}) (at {s})
        \\      (effects (font (size 1.27 1.27)) {s})
        \\    )
    , .{ name, value, id, at, justify });
}

pub fn render(comptime T: type, symbol: *const T, allocator: std.mem.Allocator) ![]const u8 {
    const property_reference = try render_property(allocator, "Reference", symbol.reference(), 0, "0.762 0.508 0", "(justify left)");
    defer allocator.free(property_reference);

    const property_value = try render_property(allocator, "Value", symbol.value, 1, "0.762 -1.016 0", "hide");
    defer allocator.free(property_value);

    const property_footprint = try render_property(allocator, "Footprint", symbol.footprint(), 2, "0 0 0", "hide");
    defer allocator.free(property_footprint);

    const property_datasheet = try render_property(allocator, "Datasheet", symbol.datasheet, 3, "0 0 0", "hide");
    defer allocator.free(property_datasheet);

    const property_manufacturer = try render_property(allocator, "Manufacturer", symbol.mpn.manufacturer, 4, "0 0 0", "hide");
    defer allocator.free(property_manufacturer);

    const property_mpn = try render_property(allocator, "MPN", symbol.mpn.number, 5, "0 0 0", "hide");
    defer allocator.free(property_mpn);

    const property_supplier = try render_property(allocator, "Supplier", symbol.spn.supplier, 6, "0 0 0", "hide");
    defer allocator.free(property_supplier);

    const property_spn = try render_property(allocator, "SPN", symbol.spn.number, 7, "0 0 0", "hide");
    defer allocator.free(property_spn);

    const property_spn2 = try render_property(allocator, symbol.spn.supplier, symbol.spn.number, 8, "0 0 0", "hide");
    defer allocator.free(property_spn2);

    const property_description = try render_property(allocator, "Description", symbol.description, 9, "0 0 0", "hide");
    defer allocator.free(property_description);

    var properties_list = std.ArrayList(u8).init(allocator);
    defer properties_list.deinit();

    for (symbol.props()) |property, i| {
        std.debug.print("prop.name = {s} .value={s} .at={s} .justify={s}\n\n", .{ property.name, property.value, property.at, property.justify });
        const prop_str = try render_property(allocator, property.name, property.value, 10 + i, property.at, property.justify);
        defer allocator.free(prop_str);
        std.debug.print("prop_str=\n\n{s}\n\n", .{prop_str});
        try properties_list.appendSlice(prop_str);
        try properties_list.appendSlice("\n");
    }

    // const properties = try std.mem.join(allocator, "\n", properties_list.items);
    // defer allocator.free(properties);

    std.debug.print("properties=\n\n{s}\n\n", .{properties_list.items});

    const base =
        \\  (symbol "{s}" (extends "{s}")
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  {s}
        \\  )
        \\
    ;

    return try fmt.allocPrint(allocator, base, .{ symbol.name, symbol.extends(), property_reference, property_value, property_footprint, property_datasheet, property_manufacturer, property_mpn, property_supplier, property_spn, property_spn2, property_description, properties_list.items });
}
