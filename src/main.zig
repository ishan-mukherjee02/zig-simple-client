const std = @import("std");
const expect = std.testing.expect;
const net = std.net;
const os = std.posix;

const Socket = struct {
    address: std.net.Address,
    socket: std.posix.socket_t,

    fn init(ip: []const u8, port: u16) !Socket {
        const parsed_address = try std.net.Address.parseIp4(ip, port);
        const sock = try std.posix.socket(std.posix.AF.INET, std.posix.SOCK.DGRAM, 0);
        errdefer os.closeSocket(sock);
        return Socket{ .address = parsed_address, .socket = sock };
    }

    fn bind(self: *Socket) !void {
        try os.bind(self.socket, &self.address.any, self.address.getOsSockLen());
    }

    fn listen(self: *Socket) !void {
        var buffer: [1024]u8 = undefined;

        while (true) {
            const received_bytes = try std.posix.recvfrom(self.socket, buffer[0..], 0, null, null);
            std.debug.print("Received {d} bytes: {s}\n", .{ received_bytes, buffer[0..received_bytes] });
        }
    }

    pub fn send(self: *Socket, data: []const u8) !void {
        const sent_bytes = try os.sendto(self.socket, data, 0, &self.address.any, self.address.getOsSockLen());
        if (sent_bytes != data.len) {
            return error.PartialWrite;
        }
        std.debug.print("Sent {d} bytes: {s}\n", .{ sent_bytes, data });
    }
};

pub fn main() !void {
    var socket = try Socket.init("127.0.0.1", 3000);
    std.debug.print("Socket created\n", .{});

    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    var input: [256]u8 = undefined;
    var input_buffer = input[0..];

    while (true) {
        try stdout.print("Enter message (type 'exit' to quit): ", .{});
        if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |user_input| {
            var trimmed_input = user_input;
            while (trimmed_input.len > 0 and (trimmed_input[trimmed_input.len - 1] == '\r')) {
                trimmed_input = trimmed_input[0 .. trimmed_input.len - 1];
            }
            if (std.mem.eql(u8, trimmed_input, "exit")) {
                break;
            }

            try socket.send(user_input);
        } else {
            break;
        }
    }
}
