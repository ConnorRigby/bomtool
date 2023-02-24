const std = @import("std");
const fmt = std.fmt;

pub const Resistor = @import("symbols/resistor.zig");
pub const easyeda = @import("easyeda.zig");

pub fn resistor(allocator: std.mem.Allocator, product: *const easyeda.Product) !Resistor {
    const component = product.component.?;

    const resistance = component.dataStr.?.head.?.c_para.?.Resistance.?;

    const name = try std.fmt.allocPrint(allocator, "R_{s}_{s}", .{ product.package.?, resistance });
    errdefer allocator.free(name);

    const value = component.title.?;
    const description = component.description.?;

    const package = try Resistor.Package.parse(product.package.?);

    const datasheet = try std.fmt.allocPrint(allocator, "https://www.lcsc.com/{s}", .{product.url.?});
    errdefer allocator.free(datasheet);

    const manufacturer = product.manufacturer.?;
    const mpn = product.mpn.?;

    return Resistor{ .name = name, .value = value, .package = package, .resistance = resistance, .datasheet = datasheet, .mpn = .{ .manufacturer = manufacturer, .number = mpn }, .spn = .{ .supplier = "LCSC", .number = product.number.? }, .description = description };
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
        "Resistance",
        symbol.resistance,
    });
}

test {
    const r = Resistor{ .name = "R_0402_1k", .value = "R_0402_1k", .package = .@"0402", .resistance = 1000, .datasheet = "https://datasheet.lcsc.com/lcsc/2206010216_UNI-ROYAL-Uniroyal-Elec-0402WGF1001TCE_C11702.pdf", .mpn = .{ .@"UNI-ROYAL(Uniroyal Elec)" = "0402WGF1001TCE" }, .spn = .{ .LCSC = "C11702" }, .description = "62.5mW Thick Film Resistors 50V ±100ppm/℃ ±1% -55℃~+155℃ 1kΩ 0402 Chip Resistor - Surface Mount ROHS" };
    const output = try render(Resistor, &r, std.testing.allocator);
    defer std.testing.allocator.free(output);

    const expected =
        \\  (symbol "R_0402_1k" (extends "R_0402_DNP")
        \\    (property "Reference" "R" (id 0) (at 0.762 0.508 0)
        \\      (effects (font (size 1.27 1.27)) (justify left))
        \\    )
        \\    (property "Value" "R_0402_1k" (id 1) (at 0.762 -1.016 0)
        \\      (effects (font (size 1.27 1.27)) (justify left))
        \\    )
        \\    (property "Footprint" "Resistor_SMD:R_0402_1005Metric" (id 2) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Datasheet" "https://datasheet.lcsc.com/lcsc/2206010216_UNI-ROYAL-Uniroyal-Elec-0402WGF1001TCE_C11702.pdf" (id 3) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Manufacturer" "UNI-ROYAL(Uniroyal Elec)" (id 4) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "MPN" "0402WGF1001TCE" (id 5) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "Supplier" "LCSC" (id 6) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "SPN" "LCSC" (id 7) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\    (property "LCSC" "C11702" (id 8) (at 0 0 0)
        \\      (effects (font (size 1.27 1.27)) hide)
        \\    )
        \\  )
    ;
    try std.testing.expectFmt(output, expected, .{});
}
