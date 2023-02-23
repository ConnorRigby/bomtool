const std = @import("std");
const json = std.json;
const http = std.http;
const fmt = std.fmt;

const Http = @import("../http.zig");

const Uri = std.Uri;

id: []const u8,
uuid: []const u8,
buffer: [20000]u8,

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

pub fn get(client: *Http, id: []const u8) !void {
  // var component: @This() = undefined;
// _ = id;
  var urlbuf = try client.allocator.allocSentinel(u8, 255, 0);
  defer client.allocator.free(urlbuf);

  // var url = try fmt.bufPrint(urlbuf, "https://httpbin.org/?id={s}", .{id});
  // var url = try fmt.bufPrintZ(urlbuf, "https://easyeda.com/api/products/{s}/svgs/", .{id});
  var url = try fmt.bufPrintZ(urlbuf, "https://easyeda.com/api/components/{s}/", .{id});
  // var uri = try Uri.parse(url);
  var response = try client.perform(url);
  std.log.info("response={s}", .{response.body});

  var token_stream = std.json.TokenStream.init(response.body);
  var options: std.json.ParseOptions = .{.allocator = client.allocator, .ignore_unknown_fields = true, .duplicate_field_behavior = .Error, .allow_trailing_data = false};
  var parsed = try std.json.parse(Payload, &token_stream, options);
  defer std.json.parseFree(Payload, parsed, options);

  std.log.info("response={any}", .{parsed});


  // var request = try client.request(uri, .{}, .{});
  // defer request.deinit();
  // std.debug.assert(request.response.headers.status == .ok);
  // std.debug.print("r.len={?d}\n", .{request.response.headers.content_length});

  // var fba = std.heap.FixedBufferAllocator.init(&buffer);
  // const allocator = fba.allocator();

  // var buffer = try client.allocator.alloc(u8, 10000);
  // defer client.allocator.free(buffer);
  // std.debug.print("starting requset\n", .{});
  // var size = try request.readAll(&component.buffer);

  // std.log.info("response[{d}]={s}", .{size, component.buffer});
}