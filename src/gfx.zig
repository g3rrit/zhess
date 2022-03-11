const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const assert = std.debug.assert;
const u = @import("util.zig");
const b = @import("board.zig");

const PieceTexture = struct {
    tex: rl.Texture2D,

    pub fn init(path: [*c]const u8, color: u.Color) PieceTexture {
        var img = rl.LoadImage(path);

        if (color == u.Color.Black) {
            rl.ImageColorInvert(&img);
        }

        rl.ImageResize(&img, u.SQUARE_SIZE, u.SQUARE_SIZE);

        return PieceTexture{
            .tex = rl.LoadTextureFromImage(img),
        };
    }

    pub fn draw(self: *PieceTexture, x: usize, y: usize) void {
        rl.DrawTexture(self.tex, @intCast(c_int, x), @intCast(c_int, y), rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }
};

pub const BoardTexture = struct {
    textures: [12]PieceTexture,

    pub fn init() BoardTexture {
        return BoardTexture{ .textures = .{
            PieceTexture.init("./res/pawn.png", u.Color.White),
            PieceTexture.init("./res/rook.png", u.Color.White),
            PieceTexture.init("./res/knight.png", u.Color.White),
            PieceTexture.init("./res/bishop.png", u.Color.White),
            PieceTexture.init("./res/queen.png", u.Color.White),
            PieceTexture.init("./res/king.png", u.Color.White),
            PieceTexture.init("./res/pawn.png", u.Color.Black),
            PieceTexture.init("./res/rook.png", u.Color.Black),
            PieceTexture.init("./res/knight.png", u.Color.Black),
            PieceTexture.init("./res/bishop.png", u.Color.Black),
            PieceTexture.init("./res/queen.png", u.Color.Black),
            PieceTexture.init("./res/king.png", u.Color.Black),
        } };
    }

    fn draw_piece(self: *BoardTexture, tag: u.Tag, color: u.Color, pos: u.Pos) void {
        var index = u.piece_to_val(tag, color);
        self.draw_piece_by_index(index, pos.x, pos.y);
    }

    fn draw_piece_by_index(self: *BoardTexture, index: usize, pos: u.Pos) void {
        assert(pos.x <= 8);
        assert(pos.y <= 8);
        self.textures[index].draw(pos.x * u.SQUARE_SIZE + u.BOARD_OFFSET, u.BOARD_SIZE - ((pos.y + 1) * u.SQUARE_SIZE) + u.BOARD_OFFSET);
    }

    pub fn draw(self: *BoardTexture, board: *b.Board) void {

        // Draw tiles
        var x: usize = 0;
        var y: usize = 0;
        while (x < 8) : (x += 1) {
            while (y < 8) : (y += 1) {
                var xpos: c_int = @intCast(c_int, u.BOARD_OFFSET + x * u.SQUARE_SIZE);
                var ypos: c_int = @intCast(c_int, u.BOARD_OFFSET + y * u.SQUARE_SIZE);
                rl.DrawRectangle(xpos, ypos, @intCast(c_int, u.SQUARE_SIZE), @intCast(c_int, u.SQUARE_SIZE), if ((x + y) % 2 == 1)
                    rl.Color{ .r = 10, .g = 10, .b = 10, .a = 30 }
                else
                    rl.Color{ .r = 100, .g = 100, .b = 10, .a = 30 });
            }
            y = 0;
        }

        // Draw pieces
        for (board.setup) |piece, i| {
            var pos: u.Pos = u.Pos.from_index(@intCast(u16, i));
            if (piece <= 12) {
                self.draw_piece_by_index(piece, pos);
            }
        }
    }
};

pub fn translate_pos(x: u32, y: u32) ?u.Pos {
    if (x <= u.BOARD_OFFSET or y <= u.BOARD_OFFSET or x >= u.BOARD_OFFSET + u.BOARD_SIZE or y >= u.BOARD_OFFSET + u.BOARD_SIZE) {
        return null;
    }

    var res_x: u32 = (x - u.BOARD_OFFSET) / u.SQUARE_SIZE;
    var res_y: u32 = 7 - ((y - u.BOARD_OFFSET) / u.SQUARE_SIZE);

    return u.Pos{
        .x = @intCast(u8, res_x),
        .y = @intCast(u8, res_y),
    };
}
