const std = @import("std");
const defs = @import("defs.zig");
const mem = std.mem;
const fmt = std.fmt;

const PLUGIN_DL_LIMIT = 1_000_000;

pub fn resolveTarget(target: []const u8) []const u8 {
    return target;
}

// https://zig.news/nameless/coming-soon-to-a-zig-near-you-http-client-5b81
pub fn httpGet(ally: mem.Allocator, url: []const u8) ![]const u8 {
    var client = std.http.Client{
        .allocator = ally,
    };
    defer client.deinit();

    const res = try client.fetch(.{
        .location = .{ .url = url },

        .headers = .{
            // tell the server we'll accept anything
            .accept_encoding = .{ .override = "*/*" },

            .host = .{ .override = url },
            .user_agent = .{ .override = "sussy gussy" },
        },
    });

    if (res.status != .ok) {
        std.log.info("bruh moment {}", .{res.status});
    }

    // TODO why do we need a download limit? should be optional
    // return req.reader().readAllAlloc(ally, PLUGIN_DL_LIMIT) catch unreachable;

    return &[_]u8{ 0, 0 };
}

pub const SizeRange = struct {
    min: usize = 0,
    max: ?usize = null,

    pub fn fmtRange(comptime self: SizeRange) []const u8 {
        return fmt.comptimePrint("{} to {s}", .{
            self.min,
            if (self.max) |v| fmt.comptimePrint("{}", .{v}) else "...",
        });
    }
};

pub fn assertArgMinN(len: usize, comptime min: usize) void {
    // Really, man? https://github.com/ziglang/zig/issues/484
    assertArgLen(len, SizeRange{ .min = min });
}

pub fn assertArgLenN(len: usize, comptime min: usize, comptime max: ?usize) void {
    // ughhhhhhhh cmon andrew, let me use default values already!
    assertArgLen(len, SizeRange{ .min = min, .max = max });
}

pub fn assertArgLen(len: usize, comptime range: SizeRange) void {
    // more short-circuit evaluation clownery <3
    const under = len < range.min;
    const over = (range.max != null) and (len > range.max.?);

    if (!(over or under)) {
        return; // congrats
    }

    // display-formatted expected range
    const expectedRange = range.fmtRange();
    const complaint = if (over) "Too many" else "Not enough";
    std.debug.print("{s} arguments ({}) given! Expected {s}\n\n", .{ complaint, len, expectedRange });
    std.posix.exit(2);
}

pub fn showHelp() void {
    std.debug.print("<help text>\n", .{});
}

pub fn parseSubcommand(cmdStr: []const u8) ?defs.RunModes {
    const cmd =
        std.meta.stringToEnum(defs.Cmds, cmdStr) orelse
        return null;

    // map commands (and aliases) to run modes
    return switch (cmd) {
        .install, .i => .Install,
    };
}
