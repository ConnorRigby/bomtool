const std = @import("std");
const json = std.json;

pub const List = @import("product/list.zig");
const Tree = @import("catalog/tree.zig");

const Http = @import("../http.zig");

pub const Price = enum {
    quantity,
    price,
};

ifRoHS: ?bool = null,
price: ?[][]union(Price) {
    quantity: usize,
    price: ?[]const u8,
} = null,
stock: ?usize = null,
mpn: ?[]const u8 = null,
number: ?[]const u8 = null,
package: ?[]const u8 = null,
manufacturer: ?[]const u8 = null,
url: ?[]const u8 = null,
image: ?[]struct {
    sort: ?usize = null,
    type: ?[]const u8 = null,
    @"900x900": ?[]const u8 = null,
    @"224x22": ?[]const u8 = null,
    @"96x96": ?[]const u8 = null,
} = null,
mfrLink: ?[]const u8 = null,
component: ?struct {
    uuid: ?[]const u8 = null,
    title: ?[]const u8 = null,
    description: ?[]const u8 = null,
    docType: ?usize = null,
    type: ?usize = null,
    szlcsc: ?struct { id: ?usize, number: ?[]const u8, step: ?usize, min: ?usize, price: ?f32, stock: ?usize, url: ?[]const u8, image: ?[]const u8 } = null,
    lcsc: ?struct {
        id: ?usize = null,
        number: ?[]const u8 = null,
        step: ?usize = null,
        min: ?usize = null,
        price: ?f32 = null,
        stock: ?usize = null,
        url: ?[]const u8 = null,
    } = null,
    owner: ?struct {
        uuid: ?[]const u8 = null,
        username: ?[]const u8 = null,
        nickname: ?[]const u8 = null,
        avatar: ?[]const u8 = null,
    } = null,
    tags: ?[][]const u8 = null,
    updateTime: ?usize = null,
    updated_at: ?[]const u8 = null,
    dataStr: ?struct {
        head: ?struct {
            docType: ?usize = null,
            editorVersion: ?[]const u8 = null,
            c_para: ?struct {
                pre: ?[]const u8 = null,
                name: ?[]const u8 = null,
                package: ?[]const u8 = null,
                BOM_Supplier: ?[]const u8 = null,
                BOM_Manufacturer: ?[]const u8 = null,
                @"BOM_Manufacturer Part": ?[]const u8 = null,
                @"BOM_Supplier Part": ?[]const u8 = null,
                @"BOM_JLCPCB Part Class": ?[]const u8 = null,
                Resistance: ?[]const u8 = null,
            } = null,
            x: ?f32 = null,
            y: ?f32 = null,
            puuid: ?[]const u8 = null,
            uuid: ?[]const u8 = null,
            utime: ?usize = null,
            importFlag: ?usize = null,
            c_spiceCmd: ?[]const u8 = null,
            hasIdFlag: ?bool = null,
        } = null,
        canvas: ?[]const u8 = null,
        shape: ?[][]const u8 = null,
        BBox: ?struct {
            x: ?f32 = null,
            y: ?f32 = null,
            width: ?f32 = null,
            height: ?f32 = null,
        } = null,
        // colors: ?[]const u8,
    } = null,
    verify: ?bool = null,
    SMT: ?bool = null,
    datastrid: ?[]const u8 = null,
    jlcOnSale: ?usize = null,
    writable: ?bool = null,
    isFavorite: ?bool = null,
    packageDetail: ?struct { uuid: ?[]const u8 = null, title: ?[]const u8 = null, docType: ?usize = null, updateTime: ?usize = null, owner: ?struct { uuid: ?[]const u8, username: ?[]const u8, nickname: ?[]const u8, avatar: ?[]const u8 } = null, datastrid: ?[]const u8 = null, writable: ?bool = null, dataStr: ?struct { head: ?struct {
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
    } = null, canvas: ?[]const u8 = null, shape: ?[][]const u8 = null, layers: ?[][]const u8 = null, objects: ?[][]const u8 = null, BBox: ?struct {
        x: ?f32 = null,
        y: ?f32 = null,
        width: ?f32 = null,
        height: ?f32 = null,
    } = null } = null } = null,
} = null,

pub fn list(client: *Http, catalog: *const Tree.Result) !List {
    const url: [:0]const u8 = try std.fmt.allocPrintZ(client.allocator, "https://easyeda.com/api/eda/product/list?version=6.5.22&catalog={d}", .{catalog.catalogId.?});
    defer client.allocator.free(url);

    var response = try client.perform(url);

    var token_stream = json.TokenStream.init(response.body);
    var options: json.ParseOptions = .{ .allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false };
    @setEvalBranchQuota(5000);
    var parsed = try json.parse(List, &token_stream, options);
    errdefer json.parseFree(List, parsed, options);
    return parsed;
}
