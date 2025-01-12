const std = @import("std");
const errors = @import("./error.zig");
const Encoder = @import("./Encoder.zig").Encoder;

/// `RleEncoder` provides a utility for run-length encoding (RLE) and decoding of data.
/// This is a form of lossless data compression where sequences of the same data value
/// are stored as a single value and a count. It is particularly effective for compressing
/// data with many repeated values.
pub const RleEncoder = struct {
    /// The memory allocator used for dynamic memory allocations during encoding and decoding.
    allocator: std.mem.Allocator,

    const Self = @This();

    pub const vtable = Encoder.VTable{
        .encode = encode,
        .decode = decode,
    };

    /// Initializes an `RleEncoder` instance.
    ///
    /// ## Parameters
    /// - `allocator`: The allocator to be used for memory management.
    ///
    /// ## Returns
    /// - A new instance of the encoder.
    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .allocator = allocator };
    }

    pub fn encoder(self: *Self) Encoder {
        return .{ .ptr = self, .vtable = &vtable };
    }

    /// Encodes the input data using run-length encoding (RLE).
    ///
    /// ## Parameters
    /// - `input`: A slice of bytes (`[]const u8`) to be encoded.
    ///
    /// ## Returns
    /// - On success: A slice of encoded bytes (`[]u8`).
    /// - On failure: An error if memory allocation fails.
    ///
    /// ## Example
    /// ```zig
    /// const encoder = RleEncoder.init(std.heap.page_allocator);
    /// const input = "aaabbbcc";
    /// const encoded = try encoder.encode(input);
    /// ```
    ///
    /// The `encoded` slice will contain the following bytes: `[3, 'a', 3, 'b', 2, 'c']`.
    pub fn encode(ctx: *anyopaque, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return errors.InputError.EmptySequence;
        }

        const self: *Self = @ptrCast(@alignCast(ctx));

        var output = std.ArrayList(u8).init(self.allocator);
        defer output.deinit();

        var count: u8 = 1;
        var current = input[0];

        for (input[1..]) |c| {
            if (c == current) {
                count += 1;

                // Handle u8 overflow
                if (count == 255) {
                    try output.append(count);
                    try output.append(current);

                    // Reset to zero to prepare for the next sequence
                    count = 0;
                }
            } else {
                // Append the completed sequence
                if (count > 0) {
                    try output.append(count);
                    try output.append(current);
                }

                count = 1;
                current = c;
            }
        }

        try output.append(count);
        try output.append(current);

        return output.toOwnedSlice();
    }

    /// Decodes the input data using run-length decoding (RLE).
    ///
    /// ## Parameters
    /// - `input`: A slice of encoded bytes (`[]const u8`) to be decoded.
    ///
    /// ## Returns
    /// - On success: A slice of decoded bytes (`[]u8`).
    /// - On failure: An error if the input is invalid or memory allocation fails.
    ///
    /// ## Example
    /// ```zig
    /// const encoder = RleEncoder.init(std.heap.page_allocator);
    /// const input = &[_]u8{ 3, 'a', 3, 'b', 2, 'c' };
    /// const decoded = try encoder.decode(input);
    /// ```
    ///
    /// The `decoded` slice will contain the original input data: `"aaabbbcc"`.
    pub fn decode(ctx: *anyopaque, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return errors.InputError.EmptySequence;
        }

        if (input.len % 2 != 0) {
            return errors.InputError.InvalidInput;
        }

        const self: *const Self = @ptrCast(@alignCast(ctx));

        var output = std.ArrayList(u8).init(self.allocator);
        defer output.deinit();

        var idx: usize = 0;
        while (idx < input.len) : (idx += 2) {
            const count = input[idx];
            const value = input[idx + 1];

            try output.appendNTimes(value, count);
        }

        return output.toOwnedSlice();
    }
};

test "RleEncoder encode and decode" {
    const allocator = std.testing.allocator;
    var rle_encoder = RleEncoder.init(allocator);
    var encoder = rle_encoder.encoder();

    const input = "aaabbbcc";
    const expected_encoded = &[_]u8{ 3, 'a', 3, 'b', 2, 'c' };
    const expected_decoded = "aaabbbcc";

    // Test encoding
    const encoded = try encoder.encode(input);
    defer allocator.free(encoded);
    try std.testing.expectEqualSlices(u8, expected_encoded, encoded);

    // Test decoding
    const decoded = try encoder.decode(encoded);
    defer allocator.free(decoded);
    try std.testing.expectEqualSlices(u8, expected_decoded, decoded);
}

test "RleEncoder encode empty input" {
    var rle_encoder = RleEncoder.init(std.testing.allocator);
    var encoder = rle_encoder.encoder();

    const input = &[_]u8{};
    const result = encoder.encode(input);
    try std.testing.expectError(errors.InputError.EmptySequence, result);
}

test "RleEncoder decode empty input" {
    var rle_encoder = RleEncoder.init(std.testing.allocator);
    var encoder = rle_encoder.encoder();

    const input = &[_]u8{};
    const result = encoder.decode(input);
    try std.testing.expectError(errors.InputError.EmptySequence, result);
}

test "RleEncoder decode invalid input" {
    var rle_encoder = RleEncoder.init(std.testing.allocator);
    var encoder = rle_encoder.encoder();

    const input = &[_]u8{ 3, 'a', 3 };
    const result = encoder.decode(input);
    try std.testing.expectError(errors.InputError.InvalidInput, result);
}
