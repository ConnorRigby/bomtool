const std = @import("std");
const fmt = std.fmt;

const symbol = @import("symbol.zig");
const Resistor = symbol.Resistor;

const R_0402_DNP = @embedFile("library/R_0402_DNP.kicad_sym_part");
const R_0603_DNP = @embedFile("library/R_0603_DNP.kicad_sym_part");
const R_0805_DNP = @embedFile("library/R_0805_DNP.kicad_sym_part");
const R_1206_DNP = @embedFile("library/R_1206_DNP.kicad_sym_part");

pub fn render(allocator: std.mem.Allocator, resistors: []Resistor) ![]const u8 {
    var libary_resistors = std.ArrayList(u8).init(allocator);
    defer libary_resistors.deinit();

    for (resistors) |resistor| {
        var library_symbol = try symbol.render(Resistor, &resistor, allocator);
        defer allocator.free(library_symbol);
        try libary_resistors.appendSlice(library_symbol);
    }

    return fmt.allocPrint(allocator,
        \\(kicad_symbol_lib (version 20211014) (generator lcsc_bomtool)
        \\{s}{s}{s}{s}
        \\{s}
        \\)
        \\
    , .{ R_0402_DNP, R_0603_DNP, R_0805_DNP, R_1206_DNP, libary_resistors.items });
}
