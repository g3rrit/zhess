const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const gfx = @import("gfx.zig");
const assert = std.debug.assert;

const WINDOW_SIZE: u32 = 620;
const BOARD_OFFSET: u32 = 10;
const BOARD_SIZE: u32 = WINDOW_SIZE - (2 * BOARD_OFFSET);
const SQUARE_SIZE: u32 = BOARD_SIZE / 8;

const PieceTag = enum {
    Pawn,
    Rook,
    Knight,
    Bishop,
    King,
    Queen,

    pub fn from_val(val : u8) PieceTag {
        return @intToEnum(PieceTag, val % 6);
    }
};

const PieceColor = enum {
    White,
    Black,

    pub fn from_val(val : u8) PieceColor {
        return if (val < 6) PieceColor.White else PieceColor.Black;
    }
};

pub fn piece_to_val(tag: PieceTag, color: PieceColor) u8 {
    return @intCast(u8, @enumToInt(tag) + (6 * @intCast(u8, @enumToInt(color))));
}

const PieceTexture = struct {
    tex: rl.Texture2D,

    pub fn init(path: [*c]const u8, c: PieceColor) PieceTexture {
        var img = rl.LoadImage(path);

        if (c == PieceColor.Black) {
            rl.ImageColorInvert(&img);
        }

        rl.ImageResize(&img, SQUARE_SIZE, SQUARE_SIZE);

        return PieceTexture {
            .tex = rl.LoadTextureFromImage(img),
        };
    }

    pub fn draw(self: *PieceTexture, x: usize, y: usize) void {
        rl.DrawTexture(
            self.tex,
            @intCast(c_int, x),
            @intCast(c_int, y),
            rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 }
        );
    }
};

const Pos = struct {
    x: u8,
    y: u8,

    pub fn to_index(self: *Pos) u16 {
        return self.y * 8 + self.x;
    }

    pub fn from_index(index: u16) Pos {
        return Pos {
            .x = @intCast(u8, index % 8),
            .y = @intCast(u8, index / 8),
        };
    }
};

const Board = struct {
    setup: [64]u4,
    white_castle: bool,
    black_castle: bool,
    last_move : struct {
        src: Pos,
        dst: Pos,
    },
    active : PieceColor,

    pub fn init() Board {
        return .{ 
            .setup = .{
                7,  8,  9, 10, 11,  9,  8,  7,
                6,  6,  6,  6,  6,  6,  6,  6,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                0,  0,  0,  0,  0,  0,  0,  0,
                1,  2,  3,  4,  5,  3,  2,  1,
            },
            .white_castle = false,
            .black_castle = false,
            .last_move = .{
                .src = Pos {
                    .x = 0, .y = 0,
                },
                .dst = Pos {
                    .x = 0, .y = 0,
                }
            },
            .active = PieceColor.White,
        };
    }

    pub fn copy(self: *Board) Board {
        return *self;
    }

    pub fn move(self: *Board, src: Pos, dst: Pos) void {

        self.last_move = .{
            .src = src,
            .dst = dst,
        };

        self.setup[dst.to_index()] = self.setup[src.to_index()];
    }

    pub fn is_mate(_: *Board) bool {
        return false;
    }

    pub fn is_legal(self: *Board, src: Pos, dst: Pos) bool {

        const src_val = self.setup[src.to_index()];
        //const src_tag = PieceTag.from_val(src_val);
        const src_color = PieceColor.from_val(src_val);

        const dst_val = self.setup[dst.to_index()];
        //const dst_tag = PieceTag.from_val(dst_val);
        const dst_color = PieceColor.from_val(dst_val);

        if (src_color != self.active) {
            return false;
        }

        if (src_color == dst_color and dst_val != 16) {
            return false;
        }

        return false;
    }

    pub fn move_checked(self: *Board, src: Pos, dst: Pos) void {

        if (self.is_legal(src, dst)) {
            return;
        }

        self.move(src, dst);
    }
};

const BoardTexture = struct {
    textures: [12]PieceTexture,

    pub fn init() BoardTexture {
        return BoardTexture { 
            .textures = .{
            PieceTexture.init("./res/pawn.png", PieceColor.White),
            PieceTexture.init("./res/rook.png", PieceColor.White),
            PieceTexture.init("./res/knight.png", PieceColor.White),
            PieceTexture.init("./res/bishop.png", PieceColor.White),
            PieceTexture.init("./res/queen.png", PieceColor.White),
            PieceTexture.init("./res/king.png", PieceColor.White),
            PieceTexture.init("./res/pawn.png", PieceColor.Black),
            PieceTexture.init("./res/rook.png", PieceColor.Black),
            PieceTexture.init("./res/knight.png", PieceColor.Black),
            PieceTexture.init("./res/bishop.png", PieceColor.Black),
            PieceTexture.init("./res/queen.png", PieceColor.Black),
            PieceTexture.init("./res/king.png", PieceColor.Black),
        }};
    }

    fn draw_piece(self: *BoardTexture, tag: PieceTag, color: PieceColor, pos: Pos) void {
        var index = piece_to_val(tag, color);
        self.draw_piece_by_index(index, pos.x, pos.y);
    }

    fn draw_piece_by_index(self: *BoardTexture, index: usize, pos: Pos) void {
        assert(pos.x <= 8);
        assert(pos.y <= 8);
        self.textures[index].draw(pos.x * SQUARE_SIZE + BOARD_OFFSET, pos.y * SQUARE_SIZE + BOARD_OFFSET);
    }

    pub fn draw(self: *BoardTexture, board: *Board) void {

        // Draw tiles
        var x: usize = 0;
        var y: usize = 0;
        while (x < 8) : (x += 1) {
            while (y < 8) : (y += 1) {
                var xpos: c_int = @intCast(c_int, BOARD_OFFSET + x * SQUARE_SIZE);
                var ypos: c_int = @intCast(c_int, BOARD_OFFSET + y * SQUARE_SIZE);
                rl.DrawRectangle(
                    xpos,
                    ypos,
                    @intCast(c_int, SQUARE_SIZE),
                    @intCast(c_int, SQUARE_SIZE),
                    if ((x + y) % 2 == 1)
                        rl.Color{ .r = 10, .g = 10, .b = 10, .a = 30 }
                    else 
                        rl.Color{ .r = 100, .g = 100, .b = 10, .a = 30 }
                );
            }
            y = 0;
        }

        // Draw pieces
        for (board.setup) |piece, i| {

            var pos: Pos = Pos.from_index(@intCast(u16, i));
            if (piece <= 12) {
                self.draw_piece_by_index(piece, pos);
            }

        }
    }

};

pub fn main() anyerror!void {
    //std.log.info("All your codebase are belong to us.", .{});

    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "ZHESS (Zig Chess)");

    var board_texture = BoardTexture.init();
    var board = Board.init();

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        board_texture.draw(&board);

        rl.EndDrawing();
    }
    rl.CloseWindow();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
