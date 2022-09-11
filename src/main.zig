const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const gfx = @import("gfx.zig");
const assert = std.debug.assert;
const u = @import("util.zig");
const b = @import("board.zig");

pub fn main() anyerror!void {
    rl.InitWindow(u.WINDOW_SIZE, u.WINDOW_SIZE, "ZHESS (Zig Chess)");

    var board_texture = gfx.BoardTexture.init();
    var board = b.Board.init();

    var src_pos: ?u.Pos = null;
    var dst_pos: ?u.Pos = null;

    var legal_bb: u64 = 0;

    while (!rl.WindowShouldClose()) {
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
            legal_bb = 0;
            var x = rl.GetMouseX();
            var y = rl.GetMouseY();
            if (x >= 0 and y >= 0) {
                src_pos = gfx.translate_pos(@intCast(u32, x), @intCast(u32, y));
                if (src_pos != null) {
                    legal_bb = board.get_legal_bb(src_pos.?);
                }
            }
        }

        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
            legal_bb = 0;
            var x = rl.GetMouseX();
            var y = rl.GetMouseY();
            if (x >= 0 and y >= 0) {
                dst_pos = gfx.translate_pos(@intCast(u32, x), @intCast(u32, y));
            }
        }

        if (src_pos != null and dst_pos != null) {
            board.move_checked(src_pos.?, dst_pos.?);
            src_pos = null;
            dst_pos = null;
        }

        // Draw
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        board_texture.draw(&board, legal_bb);

        rl.EndDrawing();
    }
    rl.CloseWindow();
}
