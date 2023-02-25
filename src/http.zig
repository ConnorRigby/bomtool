const std = @import("std");
const json = std.json;

/// HTTP Adapter wrapper for cURL commands
pub const Http = @This();

/// Common structure for all API endpoints
pub const Request = @import("http/request.zig").Request;

const cURL = @cImport({
    @cInclude("curl/curl.h");
});

/// HTTP Method
pub const Method = enum {
    GET,
    PUT,
    PATCH,
    POST,
    DELETE,
};

/// Container for a complete request's lifecycle
pub const Context = struct {
    allocator: std.mem.Allocator,
    method: ?Method = null,
    route: ?[:0]const u8 = null,
    body: ?[]const u8 = null,
    query: ?[]const u8 = null,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .allocator = allocator };
    }
    pub fn deinit(self: *@This()) void {
        if (self.route) |route| self.allocator.free(route);
        if (self.body) |body| self.allocator.free(body);
    }
};

pub const Header = struct {
    name: []u8,
    value: []u8,
};

pub const Status = struct {
    pub const Version = enum(c_long) {
        HTTP_1_0 = cURL.CURL_HTTP_VERSION_1_0,
        HTTP_1_1 = cURL.CURL_HTTP_VERSION_1_1,
        HTTP_2_0 = cURL.CURL_HTTP_VERSION_2_0,
        HTTP_3_0 = cURL.CURL_HTTP_VERSION_3,
    };
    pub const ResponseCode = enum(c_long) { Continue = 100, SwitchProtocol = 101, Processing = 102, EarlyHints = 103, Ok = 200, Created = 201, Accepted = 202, NonAuthoritative = 203, NoContent = 204, ResetContent = 205, PartialContent = 206, MultiStatus = 207, AlreadyReported = 208, IMUsed = 212, Redirected = 300, MovedPermanently = 301, Found = 302, SeeOther = 303, NotModified = 304, UseProxy = 305, SwitchProxy = 306, TemporaryRedirect = 307, PermanentRedirect = 308, BadRequest = 400, Unauthorized = 401, PaymentRequired = 402, Forbidden = 403, NotFound = 404, MethodNotAllowed = 405, NotAcceptable = 406, ProxyAuthenticationRequired = 407, RequestTimeout = 408, Conflict = 409, Gone = 410, LengthRequred = 411, PreconditionFailed = 412, PayloadTooLarge = 413, URIRequestTookTooLong = 414, UnsupportedMediaType = 415, RangeNotSuitable = 416, ExpectationFailed = 417, IAMATeapot = 418, MisdirectedRequest = 421, UnprocessableEntry = 422, Locked = 423, FailedDependency = 424, TooEarly = 425, UpgradeRequired = 426, PreconditionRequired = 428, TooManyRequests = 429, request_headersTooLarge = 431, UnavailableForLegalReasons = 451, InternalError = 500, NotImplemented = 501, BadGateway = 502, ServiceUnavailable = 503, GatewayTimeout = 504, HTTPVersionNotSupported = 505, InsufficientStorage = 507, LoopDetected = 508, NotExtended = 510, NetworkAuthenticationRequired = 511, _ };
    http_version: Version,
    response_code: ResponseCode,
};

/// Common response structure. Body data is
/// body is not parsed in any way
pub const Response = struct {
    headers: []Header,
    status: Status,
    body: []u8,
    pub fn deinit(self: *Response, allocator: std.mem.Allocator) void {
        for (self.headers) |header| {
            allocator.free(header.name);
            allocator.free(header.value);
        }
        allocator.free(self.headers);
        allocator.free(self.body);
    }
};

allocator: std.mem.Allocator,
request_headers: ?*cURL.curl_slist,

/// Initialize the Http container
pub fn init(allocator: std.mem.Allocator) !Http {
    // global curl init, or fail
    if (cURL.curl_global_init(cURL.CURL_GLOBAL_ALL) != cURL.CURLE_OK)
        return error.CURLGlobalInitFailed;
    errdefer cURL.curl_global_cleanup();
    var headers: ?*cURL.curl_slist = null;
    errdefer cURL.curl_slist_free_all(headers);

    return .{
        .allocator = allocator,
        .request_headers = headers,
    };
}

/// execute a composed request, the request should be a Request(type, type, type) struct
pub fn executeRequest(self: *Http, comptime T: type, request: anytype) !T {
    // initialize a context
    var ctx = Context.init(self.allocator);
    defer ctx.deinit();

    // prepare the request
    try request.prepare(&ctx);

    // make the HTTP request
    var response = try self.perform(&ctx);
    defer response.deinit(self.allocator);
    switch (response.status.response_code) {
        .Ok, .Created, .Accepted, .NoContent => return try request.perform(&ctx, response.body),
        else => @panic("perform not implemented"),
    }
}

// internal perform request impl
pub fn perform(self: *Http, request_url: [:0]const u8) !Response {
    const handle = cURL.curl_easy_init() orelse return error.curl_easy_init;
    defer cURL.curl_easy_cleanup(handle);

    var response_buffer = std.ArrayList(u8).init(self.allocator);
    errdefer response_buffer.deinit();

    var url = cURL.curl_url();
    defer cURL.curl_url_cleanup(url);
    if (cURL.curl_url_set(url, cURL.CURLUPART_URL, request_url, 0) != cURL.CURLE_OK)
        return error.CURLUPART_URL;

    // if (context.route) |route| {
    //     if (cURL.curl_url_set(url, cURL.CURLUPART_PATH, route.ptr, 0) != cURL.CURLE_OK)
    //         return error.CURLUPART_PATH;
    // } else unreachable;
    // if (context.query) |query| {
    //     var query_data = try self.allocator.allocSentinel(u8, query.len, 0);
    //     defer self.allocator.free(query_data);
    //     std.mem.copy(u8, query_data, query);

    //     if (cURL.curl_url_set(url, cURL.CURLUPART_QUERY, query_data.ptr, cURL.CURLUPART_QUERY) != cURL.CURLE_OK)
    //         return error.CURLUPART_QUERY;
    // }
    var url_str: [*c]u8 = null;
    defer cURL.curl_free(url_str);

    if (cURL.curl_url_get(url, cURL.CURLUPART_URL, &url_str, 0) != cURL.CURLE_OK)
        return error.curl_url_get;

    std.debug.print("starting request: {s}\n", .{url_str});

    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url_str) != cURL.CURLE_OK)
        return error.CURLUPART_URL;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
        return error.CURLOPT_WRITEFUNCTION;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, &response_buffer) != cURL.CURLE_OK)
        return error.CURLOPT_WRITEDATA;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_HTTPHEADER, self.request_headers) != cURL.CURLE_OK)
        return error.CURLOPT_HTTPHEADER;

    // var method: [*c]const u8 = switch (context.method.?) {
    //     .GET => "GET",
    //     .PUT => "PUT",
    //     .PATCH => "PATCH",
    //     .POST => "POST",
    //     .DELETE => "DELETE",
    // };
    // if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_CUSTOMREQUEST, method) != cURL.CURLE_OK)
    //     return error.CURLOPT_CUSTOMREQUEST;

    // if (context.body) |body| {
    //     std.debug.print("request body={any}", .{body});
    //     var postDataZ = try self.allocator.allocSentinel(u8, body.len, 0);
    //     defer self.allocator.free(postDataZ);
    //     std.mem.copy(u8, postDataZ, body);
    //     switch (context.method.?) {
    //         .POST => if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_POSTFIELDS, postDataZ.ptr) != cURL.CURLE_OK) return error.CURLOPT_POSTFIELDS,
    //         else => @panic("invalid body for method"),
    //     }
    //     // this perform function has to exist twice because of the scope of the `context.body`
    //     // check. TODO: move the sentinel dupe into the `prepare` function
    //     if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK) return error.curl_easy_perform;
    // } else if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK) return error.curl_easy_perform;
    if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK) return error.curl_easy_perform;

    var headers = std.ArrayList(Header).init(self.allocator);
    defer headers.deinit(); // gets toOwnedSlice()'d later

    var response_code: c_long = 0;
    var http_version: c_long = 0;

    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_RESPONSE_CODE, &response_code) != cURL.CURLE_OK)
        return error.CURLINFO_RESPONSE_CODE;
    if (response_code == 0) return error.CURLINFO_RESPONSE_CODE;

    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_HTTP_VERSION, &http_version) != cURL.CURLE_OK)
        return error.CURLINFO_HTTP_VERSION;
    if (http_version == 0) return error.CURLINFO_HTTP_VERSION;

    var status: Status = .{ .response_code = @intToEnum(Status.ResponseCode, response_code), .http_version = @intToEnum(Status.Version, http_version) };

    var prevHeader: ?*cURL.curl_header = null;
    while (cURL.curl_easy_nextheader(handle, cURL.CURLH_HEADER, 0, prevHeader)) |next| {
        try headers.append(.{ .name = try self.allocator.dupe(u8, std.mem.span(next.*.name)), .value = try self.allocator.dupe(u8, std.mem.span(next.*.value)) });
        prevHeader = next;
    }
    const origin: c_int = cURL.CURLH_HEADER | cURL.CURLH_1XX | cURL.CURLH_TRAILER;
    while (cURL.curl_easy_nextheader(handle, origin, -1, prevHeader)) |next| {
        try headers.append(.{ .name = try self.allocator.dupe(u8, std.mem.span(next.*.name)), .value = try self.allocator.dupe(u8, std.mem.span(next.*.value)) });
        prevHeader = next;
    }

    // std.debug.print("\n\n=====request {s}=====\n\n", .{url_str});
    // std.debug.print("body= {s}\n", .{response_buffer.items});

    return .{
        .headers = try headers.toOwnedSlice(),
        .status = status,
        .body = try response_buffer.toOwnedSlice(),
    };
}

fn writeToArrayListCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer = @intToPtr(*std.ArrayList(u8), @ptrToInt(user_data));
    var typed_data = @intToPtr([*]u8, @ptrToInt(data));
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}

pub fn deinit(api: *Http) void {
    _ = api;
    cURL.curl_global_cleanup();
}
