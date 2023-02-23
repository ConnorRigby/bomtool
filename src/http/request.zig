const std = @import("std");
const json = std.json;

const Http = @import("../http.zig");
const Context = Http.Context;

pub fn Request(
    comptime T: type,
    comptime Body: type,
    comptime Query: type,
) type {
    return struct {
        const Self = @This();
        const State = enum { init, prepare, perform };
        const Response = T;
        state: State,
        method: Http.Method,
        route: []const []const u8,
        body: Body,
        query: Query,

        pub fn init(request: struct {
            method: Http.Method,
            route: []const []const u8,
            body: Body,
            query: Query,
        }) Self {
            return .{ .state = .init, .method = request.method, .route = request.route, .body = request.body, .query = request.query };
        }

        pub fn post(request: struct {
            body: Body,
            route: []const []const u8,
        }) Self {
            std.debug.print("\n\n\npost={s}\n\n\n", .{request.route});
            return init(.{ .method = .POST, .route = request.route, .body = request.body, .query = null });
        }

        pub fn get(request: struct {
            query: Query = null,
            route: []const []const u8,
        }) Self {
            return init(.{ .method = .GET, .route = request.route, .body = null, .query = request.query });
        }

        pub fn prepare(self: *Self, ctx: *Http.Context) !void {
            std.debug.print("prepare={*}{any}\n\n\n\n", .{self.route, self.route});
            switch (self.state) {
                .init => {},
                inline else => |invalid| std.log.err("Invalid state: {s} for request: {any}", .{ @tagName(invalid), self }),
            }
            ctx.method = self.method;
            std.debug.assert(self.route.len > 0);
            std.debug.print("\n\nroute={s}\n\n", .{self.route});
            var endpoint_route = try std.mem.join(ctx.allocator, "/", self.route);
            defer ctx.allocator.free(endpoint_route);

            var route = try std.fmt.allocPrintZ(ctx.allocator, "/api/v10/{s}", .{endpoint_route});
            errdefer ctx.allocator.free(route);
            std.debug.print("route={s}\n\n", .{route});

            if (ctx.method.? != .GET) {
                var body = try json.stringifyAlloc(ctx.allocator, self.body, .{ .whitespace = null, .emit_null_optional_fields = false, .string = .{ .String = .{ .escape_solidus = false, .escape_unicode = true } } });
                errdefer ctx.allocator.free(body);
                ctx.body = body;
            }

            ctx.route = route;
            self.state = .prepare;
        }

        pub fn perform(self: *Self, ctx: *Http.Context, response: []const u8) !T {
            switch (self.state) {
                .prepare => {},
                inline else => |invalid| std.log.err("Invalid state: {s} for request: {any}", .{ @tagName(invalid), self }),
            }
            var token_stream = json.TokenStream.init(response);
            self.state = .perform;
            @setEvalBranchQuota(5000);
            return json.parse(T, &token_stream, .{ .allocator = ctx.allocator, .duplicate_field_behavior = .Error, .ignore_unknown_fields = true, .allow_trailing_data = true });
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator, value: T) void {
            _ = self;
            return json.parseFree(T, value, .{ .allocator = allocator, .duplicate_field_behavior = .Error, .ignore_unknown_fields = true, .allow_trailing_data = true });
        }
    };
}

test {
    const TestResponse = struct {
        data: []const u8,
        optional: ?[]const u8 = null,
    };
    const TestRequest = Request(TestResponse, struct { hello: []const u8 }, @TypeOf(null));

    // initialize a runtime ctx
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    // initialize a request
    var message_id = "1420070400000";
    var request = TestRequest.init(.{ .method = .POST, .route = &[_][]const u8{ "channels", "1420070400000", "messages", message_id }, .body = .{ .hello = "world" }, .query = null });

    // prepare the request for sending the request
    try request.prepare(&ctx);

    // handle the performed request
    var response = try request.perform(&ctx, "{\"data\":\"response data\"}");
    defer request.deinit(std.testing.allocator, response);
    try std.testing.expectEqual(ctx.method.?, request.method);
    try std.testing.expectFmt(ctx.route.?, "{s}", .{"/api/v10/channels/1420070400000/messages/1420070400000"});
    try std.testing.expectFmt(response.data, "{s}", .{"response data"});
}

test {
    const TestResponse = struct {
        data: []const u8,
        optional: ?[]const u8 = null,
    };
    const TestRequest = Request(TestResponse, struct { hello: []const u8 }, @TypeOf(null));

    // initialize a runtime ctx
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    // initialize a request
    var message_id = "1420070400000";
    var request = TestRequest.post(.{
        .route = &[_][]const u8{ "channels", "1420070400000", "messages", message_id },
        .body = .{ .hello = "world" },
    });

    // prepare the request for sending the request
    try request.prepare(&ctx);

    // handle the performed request
    var response = try request.perform(&ctx, "{\"data\":\"response data\"}");
    defer request.deinit(std.testing.allocator, response);
    try std.testing.expectEqual(ctx.method.?, request.method);
    try std.testing.expectFmt(ctx.route.?, "{s}", .{"/api/v10/channels/1420070400000/messages/1420070400000"});
    try std.testing.expectFmt(response.data, "{s}", .{"response data"});
}
