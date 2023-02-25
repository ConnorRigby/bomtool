const std = @import("std");

const properties = @import("../properties.zig");
const ManufacturerPartNumber = properties.ManufacturerPartNumber;
const SupplierPartNumber = properties.SupplierPartNumber;
const Property = properties.Property;

pub const Package = enum {
    SMA,
    pub fn parse(package: []const u8) !Package {
        if (std.ascii.eqlIgnoreCase(package, "SMA(DO-214AC)")) return .SMA;
        if (std.ascii.eqlIgnoreCase(package, "SMA_L4.2-W2.7-LS5.3-RD")) return .SMA;
        if (std.ascii.eqlIgnoreCase(package, "SMA")) return .SMA;
        return error.UnknownPackage;
    }
};

name: []const u8,
value: []const u8,
package: Package,

/// Datasheet link
datasheet: []const u8,

/// Manufacturer part number
mpn: ManufacturerPartNumber,

/// Supplier part number
spn: SupplierPartNumber,

description: []const u8,

pub fn extends(self: *const @This()) []const u8 {
    return switch (self.package) {
        .SMA => "D_SMA_DNP",
    };
}

pub fn reference(self: *const @This()) []const u8 {
    _ = self;
    return "D";
}

pub fn footprint(self: *const @This()) []const u8 {
    return switch (self.package) {
        .SMA => "Diode_SMD:D_SMA",
    };
}

pub fn props(self: *const @This()) []Property {
    _ = self;
    return &[_]Property{};
}
