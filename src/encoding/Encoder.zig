pub const Encoder = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    encode: *const fn (ctx: *anyopaque, input: []const u8) anyerror![]const u8,
    decode: *const fn (ctx: *anyopaque, input: []const u8) anyerror![]const u8,
};

pub fn encode(self: *Encoder, input: []const u8) ![]const u8 {
    return self.vtable.encode(self.ptr, input);
}

pub fn decode(self: *Encoder, input: []const u8) ![]const u8 {
    return self.vtable.decode(self.ptr, input);
}
