const std = @import("std");

const properties = @import("../properties.zig");
const ManufacturerPartNumber = properties.ManufacturerPartNumber;
const SupplierPartNumber = properties.SupplierPartNumber;

pub const Package = enum {
    @"0402",
    @"0603",
    @"0805",
    pub fn parse(package: []const u8) !Package {
        if (std.ascii.eqlIgnoreCase(package, "0402")) return .@"0402";
        if (std.ascii.eqlIgnoreCase(package, "0603")) return .@"0603";
        if (std.ascii.eqlIgnoreCase(package, "0805")) return .@"0805";
        return error.UnknownPackage;
    }
};

name: []const u8,
value: []const u8,
package: Package,
capacitance: []const u8,

/// Datasheet link
datasheet: []const u8,

/// Manufacturer part number
mpn: ManufacturerPartNumber,

/// Supplier part number
spn: SupplierPartNumber,

description: []const u8,

pub fn extends(self: *const @This()) []const u8 {
    return switch (self.package) {
        .@"0402" => "C_0402_DNP",
        .@"0603" => "C_0603_DNP",
        .@"0805" => "C_0805_DNP",
    };
}

pub fn reference(self: *const @This()) []const u8 {
    _ = self;
    return "C";
}

pub fn footprint(self: *const @This()) []const u8 {
    return switch (self.package) {
        .@"0402" => "Capacitor_SMD:C_0402_1005Metric",
        .@"0603" => "Capacitor_SMD:C_0603_1608Metric",
        .@"0805" => "Capacitor_SMD:C_0805_2012Metric",
    };
}

pub fn property(self: *const @This()) []const u8 {
    _ = self;
    return "Capacitance";
}

pub fn property_value(self: *const @This()) []const u8 {
    return self.capacitance;
}
