const std = @import("std");

pub const WINDOW_SIZE: u32 = 620;
pub const BOARD_OFFSET: u32 = 10;
pub const BOARD_SIZE: u32 = WINDOW_SIZE - (2 * BOARD_OFFSET);
pub const SQUARE_SIZE: u32 = BOARD_SIZE / 8;

pub const Tag = enum {
    Pawn,
    Rook,
    Knight,
    Bishop,
    Queen,
    King,

    pub fn from_val(val : u8) Tag {
        return @intToEnum(Tag, val % 6);
    }
};

pub const Color = enum {
    White,
    Black,

    pub fn from_val(val : u8) Color {
        return if (val < 6) Color.White else Color.Black;
    }

    pub fn not(self: Color) Color {
        return if (self == Color.White) Color.Black else Color.White;
    }

    pub fn dir(self: Color) i8 {
        return if (self == Color.White) 1 else -1;
    }
};

pub fn piece_to_val(tag: Tag, color: Color) u4 {
    return @intCast(u4, @enumToInt(tag) + (6 * @intCast(u8, @enumToInt(color))));
}

pub const Pos = struct {
    x: u8,
    y: u8,

    pub fn init(x: u8, y: u8) Pos {
        return Pos {
            .x = x,
            .y = y,
        };
    }

    pub fn to_index(self: Pos) u16 {
        return Pos._to_index(self.x, self.y);
    }

    pub fn from_index(index: u16) Pos {
        return Pos {
            .x = @intCast(u8, index % 8),
            .y = @intCast(u8, index / 8),
        };
    }
    
    pub fn _to_index(x: u8, y: u8) u16 {
        return @intCast(u16, y) * 8 + @intCast(u16, x);
    }
};
