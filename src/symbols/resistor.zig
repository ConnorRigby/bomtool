const std = @import("std");

const properties = @import("../properties.zig");
const ManufacturerPartNumber = properties.ManufacturerPartNumber;
const SupplierPartNumber = properties.SupplierPartNumber;

pub const Package = enum {
    @"0402",
    @"0603",
    @"0805",
    @"1206",
    pub fn parse(package: []const u8) !Package {
        if (std.ascii.eqlIgnoreCase(package, "0402")) return .@"0402";
        if (std.ascii.eqlIgnoreCase(package, "0603")) return .@"0603";
        if (std.ascii.eqlIgnoreCase(package, "0805")) return .@"0805";
        if (std.ascii.eqlIgnoreCase(package, "1206")) return .@"1206";
        return error.UnknownPackage;
    }
};

name: []const u8,
value: []const u8,
package: Package,
resistance: []const u8,

/// Datasheet link
datasheet: []const u8,

/// Manufacturer part number
mpn: ManufacturerPartNumber,

/// Supplier part number
spn: SupplierPartNumber,

description: []const u8,

pub fn extends(self: *const @This()) []const u8 {
    return switch (self.package) {
        .@"0402" => "R_0402_DNP",
        .@"0603" => "R_0603_DNP",
        .@"0805" => "R_0805_DNP",
        .@"1206" => "R_1206_DNP",
    };
}

pub fn reference(self: *const @This()) []const u8 {
    _ = self;
    return "R";
}

pub fn footprint(self: *const @This()) []const u8 {
    return switch (self.package) {
        .@"0402" => "Resistor_SMD:R_0402_1005Metric",
        .@"0603" => "Resistor_SMD:R_0603_1608Metric",
        .@"0805" => "Resistor_SMD:R_0805_2012Metric",
        .@"1206" => "Resistor_SMD:R_1206_3216Metric",
    };
}
