pub const Szlcsc = struct {
    id: ?usize = null,
    number: ?[]const u8 = null,
    step: ?usize = null,
    min: ?usize = null,
    price: ?f32 = null,
    stock: ?usize = null,
    url: ?[]const u8 = null,
    image: ?[]const u8 = null,
};

pub const Lcsc = struct {
    id: ?usize = null,
    number: ?[]const u8 = null,
    step: ?usize = null,
    min: ?usize = null,
    price: ?f32 = null,
    stock: ?usize = null,
    url: ?[]const u8 = null,
};

pub const Owner = struct {
    uuid: ?[]const u8 = null,
    username: ?[]const u8 = null,
    nickname: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
};

pub const BBox = struct {
    x: ?f32 = null,
    y: ?f32 = null,
    width: ?f32 = null,
    height: ?f32 = null,
};

pub const DataStr = struct {
    pub const CPara = struct {
        pre: ?[]const u8 = null,
        name: ?[]const u8 = null,
        package: ?[]const u8 = null,
        BOM_Supplier: ?[]const u8 = null,
        BOM_Manufacturer: ?[]const u8 = null,
        @"BOM_Manufacturer Part": ?[]const u8 = null,
        @"BOM_Supplier Part": ?[]const u8 = null,
        @"BOM_JLCPCB Part Class": ?[]const u8 = null,
        nameAlias: ?[]const u8 = null,
        Resistance: ?[]const u8 = null,
        Capacitance: ?[]const u8 = null,
    };
    pub const Head = struct {
        docType: ?usize = null,
        editorVersion: ?[]const u8 = null,
        c_para: ?CPara = null,
        x: ?f32 = null,
        y: ?f32 = null,
        puuid: ?[]const u8 = null,
        uuid: ?[]const u8 = null,
        utime: ?usize = null,
        importFlag: ?usize = null,
        c_spiceCmd: ?[]const u8 = null,
        hasIdFlag: ?bool = null,
    };
    head: ?Head = null,
    canvas: ?[]const u8 = null,
    shape: ?[][]const u8 = null,
    BBox: ?BBox = null,
    // colors: ?[]const u8,
};

pub const PackageDetail = struct { uuid: ?[]const u8 = null, title: ?[]const u8 = null, docType: ?usize = null, updateTime: ?usize = null, owner: ?Owner = null, datastrid: ?[]const u8 = null, writable: ?bool = null, dataStr: ?struct { head: ?struct {
    docType: ?usize = null,
    editorVersion: ?[]const u8 = null,
    c_para: ?struct {
        pre: ?[]const u8 = null,
        package: ?[]const u8 = null,
        link: ?[]const u8 = null,
        Contributor: ?[]const u8 = null,
        @"3DModel": ?[]const u8 = null,
    } = null,
    x: ?f32 = null,
    y: ?f32 = null,
    uuid: ?[]const u8 = null,
    utime: ?usize = null,
    importFlag: ?usize = null,
    transformList: ?[]const u8 = null,
    hasIdFlag: ?bool = null,
    newgId: ?bool = null,
} = null, canvas: ?[]const u8 = null, shape: ?[][]const u8 = null, layers: ?[][]const u8 = null, objects: ?[][]const u8 = null, BBox: ?BBox = null } = null };

uuid: ?[]const u8 = null,
title: ?[]const u8 = null,
description: ?[]const u8 = null,
docType: ?usize = null,
type: ?usize = null,
szlcsc: ?Szlcsc = null,
lcsc: ?Lcsc = null,
owner: ?Owner = null,
tags: ?[][]const u8 = null,
updateTime: ?usize = null,
updated_at: ?[]const u8 = null,
dataStr: ?DataStr = null,
verify: ?bool = null,
SMT: ?bool = null,
datastrid: ?[]const u8 = null,
jlcOnSale: ?usize = null,
writable: ?bool = null,
isFavorite: ?bool = null,
packageDetail: ?PackageDetail = null,
