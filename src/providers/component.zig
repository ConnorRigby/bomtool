const std = @import("std");
const json = std.json;
const http = std.http;
const fmt = std.fmt;

const Uri = std.Uri;

id: []const u8,
uuid: []const u8,

pub const Result = struct {
  component_uuid: []const u8,
  updateTime: usize,
  svg: []const u8
};

pub const Payload = struct {
  success: bool,
  code: usize,
  result: []Result,
};

pub fn get(client: *http.Client, id: []const u8) !void {
  var urlbuf = try client.allocator.alloc(u8, 255);
  defer client.allocator.free(urlbuf);

  var url = try fmt.bufPrint(urlbuf, "https://easyeda.com/api/products/{s}/svgs", .{id});
  var uri = try Uri.parse(url);

  var request = try client.request(uri, .{}, .{});
  defer request.deinit();

  var buffer = try client.allocator.alloc(u8, 100000);
  defer client.allocator.free(buffer);

  var size = try request.readAll(buffer);

  std.log.info("response[{d}]={s}", .{size, buffer});
}