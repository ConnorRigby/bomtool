const std = @import("std");
const fmt = std.fmt;

const symbol = @import("symbol.zig");

const R_0402_DNP = @embedFile("library/R_0402_DNP.kicad_sym_part");
const R_0603_DNP = @embedFile("library/R_0603_DNP.kicad_sym_part");
const R_0805_DNP = @embedFile("library/R_0805_DNP.kicad_sym_part");
const R_1206_DNP = @embedFile("library/R_1206_DNP.kicad_sym_part");

const C_0402_DNP = @embedFile("library/C_0402_DNP.kicad_sym_part");
const C_0603_DNP = @embedFile("library/C_0603_DNP.kicad_sym_part");
const C_0805_DNP = @embedFile("library/C_0805_DNP.kicad_sym_part");

pub fn render(allocator: std.mem.Allocator, product_symbols: []symbol.ProductSymbol) ![]const u8 {
    var library_symbols = std.ArrayList(u8).init(allocator);
    defer library_symbols.deinit();

    for (product_symbols) |product_symbol| switch (product_symbol) {
        inline else => |t| {
            var library_symbol = try symbol.render(@TypeOf(t), &t, allocator);
            defer allocator.free(library_symbol);
            try library_symbols.appendSlice(library_symbol);
        },
    };

    return fmt.allocPrint(allocator,
        \\(kicad_symbol_lib (version 20211014) (generator lcsc_bomtool)
        \\{s}{s}{s}{s}{s}{s}{s}
        \\{s})
        \\
    , .{ R_0402_DNP, R_0603_DNP, R_0805_DNP, R_1206_DNP, C_0402_DNP, C_0603_DNP, C_0805_DNP, library_symbols.items });
}
