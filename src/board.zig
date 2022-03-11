const std = @import("std");
const u = @import("util.zig");

pub const BB = struct {
    pub fn _set(bb: u64, x: u8, y: u8) u64 {
        if (x >= 8 or y >= 8) {
            return bb;
        }
        var shift: u6 = @intCast(u6, y * 8 + x);
        return bb | (@as(u64, 1) << shift);
    }

    pub fn set(bb: u64, pos: u.Pos) u64 {
        return BB._set(bb, pos.x, pos.y);
    }

    pub fn _unset(bb: u64, x: u8, y: u8) u64 {
        if (x >= 8 or y >= 8) {
            return bb;
        }
        var shift: u6 = @intCast(u6, y * 8 + x);
        return bb & (~(1 << shift));
    }

    pub fn unset(bb: u64, pos: u.Pos) u64 {
        return BB._unset(bb, pos.x, pos.y);
    }

    pub fn _in(bb: u64, x: u8, y: u8) bool {
        if (x >= 8 or y >= 8) {
            return false;
        }
        var shift: u6 = @intCast(u6, y * 8 + x);
        return (bb & (@as(u64, 1) << shift)) != 0;
    }

    pub fn in(bb: u64, pos: u.Pos) bool {
        return BB._in(bb, pos.x, pos.y);
    }
};

pub const Board = struct {
    setup: [64]u4,
    castle: [6]bool, // WKing, BKing, left WRook, right WRook, left BRook, right BRook
    last_move: struct {
        src: u.Pos,
        dst: u.Pos,
    },
    active: u.Color,

    pub fn init() Board {
        return .{
            .setup = .{
                1,  2,  3,  4,  5,  3,  2,  1,
                0,  0,  0,  0,  0,  0,  0,  0,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                15, 15, 15, 15, 15, 15, 15, 15,
                6,  6,  6,  6,  6,  6,  6,  6,
                7,  8,  9,  10, 11, 9,  8,  7,
            },
            .castle = .{ false, false, false, false, false, false },
            .last_move = .{ .src = u.Pos{
                .x = 0,
                .y = 0,
            }, .dst = u.Pos{
                .x = 0,
                .y = 0,
            } },
            .active = u.Color.White,
        };
    }

    fn at(self: *Board, pos: u.Pos) u4 {
        return self.setup[pos.to_index()];
    }

    fn _at(self: *Board, x: u8, y: u8) u4 {
        return self.setup[u.Pos._to_index(x, y)];
    }

    fn is(self: *Board, pos: u.Pos, color: ?u.Color, tag: ?u.Tag) bool {
        if (pos.x > 7 or pos.y > 7) {
            return false;
        }

        const dst_val = self.setup[pos.to_index()];
        const dst_tag = u.Tag.from_val(dst_val);
        const dst_color = u.Color.from_val(dst_val);

        if (tag != null and color != null) {
            return tag.? == dst_tag and color.? == dst_color;
        } else if (tag != null and color == null) {
            return tag.? == dst_tag;
        } else if (tag == null and color != null) {
            return color.? == dst_color and (dst_val < 12);
        } else {
            return (dst_val < 12);
        }
    }

    fn _is(self: *Board, x: u8, y: u8, color: ?u.Color, tag: ?u.Tag) bool {
        return self.is(u.Pos.init(x, y), color, tag);
    }

    fn get_bb_attack_rook(self: *Board, _bb: u64, pos: u.Pos, attack: bool) u64 {
        var bb: u64 = _bb;

        const color = u.Color.from_val(self.at(pos));

        var dir: u8 = 1;
        while (pos.x + dir < 8) : (dir += 1) {
            bb = if (attack or !self._is(pos.x + dir, pos.y, color, null)) BB._set(bb, pos.x + dir, pos.y) else bb;
            if (self._is(pos.x + dir, pos.y, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.y + dir < 8) : (dir += 1) {
            bb = if (attack or !self._is(pos.x, pos.y + dir, color, null)) BB._set(bb, pos.x, pos.y + dir) else bb;
            if (self._is(pos.x, pos.y + dir, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.x >= dir) : (dir += 1) {
            bb = if (attack or !self._is(pos.x -% dir, pos.y, color, null)) BB._set(bb, pos.x -% dir, pos.y) else bb;
            if (self._is(pos.x -% dir, pos.y, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.y >= dir) : (dir += 1) {
            bb = if (attack or !self._is(pos.x, pos.y -% dir, color, null)) BB._set(bb, pos.x, pos.y -% dir) else bb;
            if (self._is(pos.x, pos.y -% dir, null, null)) {
                break;
            }
        }
        return bb;
    }

    fn get_bb_attack_bishop(self: *Board, _bb: u64, pos: u.Pos, attack: bool) u64 {
        var bb: u64 = _bb;

        const color = u.Color.from_val(self.at(pos));

        var dir: u8 = 1;
        while (pos.x + dir < 8 and pos.y + dir < 8) : (dir += 1) {
            bb = if (attack or !self._is(pos.x + dir, pos.y + dir, color, null)) BB._set(bb, pos.x + dir, pos.y + dir) else bb;
            if (self._is(pos.x + dir, pos.y + dir, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.x + dir < 8 and pos.y >= dir) : (dir += 1) {
            bb = if (attack or !self._is(pos.x + dir, pos.y -% dir, color, null)) BB._set(bb, pos.x + dir, pos.y -% dir) else bb;
            if (self._is(pos.x + dir, pos.y -% dir, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.x >= dir and pos.y >= dir) : (dir += 1) {
            bb = if (attack or !self._is(pos.x -% dir, pos.y -% dir, color, null)) BB._set(bb, pos.x -% dir, pos.y -% dir) else bb;
            if (self._is(pos.x -% dir, pos.y -% dir, null, null)) {
                break;
            }
        }
        dir = 1;
        while (pos.x >= dir and pos.y + dir < 8) : (dir += 1) {
            bb = if (attack or !self._is(pos.x -% dir, pos.y + dir, color, null)) BB._set(bb, pos.x -% dir, pos.y + dir) else bb;
            if (self._is(pos.x -% dir, pos.y + dir, null, null)) {
                break;
            }
        }
        return bb;
    }

    fn get_bb(self: *Board, _bb: u64, pos: u.Pos, _color: ?u.Color, attack: bool) u64 {
        var bb: u64 = _bb;

        const i = pos.to_index();
        const val = self.setup[i];

        if (val >= 12) {
            return bb;
        }

        const tag = u.Tag.from_val(val);
        const color = u.Color.from_val(val);

        if (_color != null and color != _color.?) {
            return bb;
        }

        switch (tag) {
            u.Tag.Pawn => {
                const dir: i8 = color.dir();
                const last_move_piece: u.Tag = u.Tag.from_val(self.at(self.last_move.dst));

                // En passant
                // This should work as the pawn can only move 2 if it has been on y == 1 or 6
                if (!attack and
                    (last_move_piece == u.Tag.Pawn and
                    self.last_move.dst.x + 1 == pos.x and
                    (@intCast(i8, self.last_move.src.y) -% @intCast(i8, self.last_move.dst.y)) * dir == 2))
                {
                    bb = BB._set(bb, pos.x -% 1, @intCast(u8, @intCast(i8, pos.y) + dir));
                }

                if (!attack and
                    (last_move_piece == u.Tag.Pawn and
                    self.last_move.dst.x == pos.x + 1 and
                    (@intCast(i8, self.last_move.src.y) -% @intCast(i8, self.last_move.dst.y)) * dir == 2))
                {
                    bb = BB._set(bb, pos.x + 1, @intCast(u8, @intCast(i8, pos.y) + dir));
                }

                // move forward
                if (!attack and !self._is(pos.x, @intCast(u8, @intCast(i8, pos.y) + dir), null, null)) {
                    bb = BB._set(bb, pos.x, @intCast(u8, @intCast(i8, pos.y) + dir));
                    if (color == u.Color.White and pos.y == 1 and !self._is(pos.x, pos.y + 2, null, null)) {
                        bb = BB._set(bb, pos.x, pos.y + 2);
                    }
                    if (color == u.Color.Black and pos.y == 6 and !self._is(pos.x, pos.y -% 2, null, null)) {
                        bb = BB._set(bb, pos.x, pos.y -% 2);
                    }
                }

                // diagonal attack
                bb = if (attack or self._is(pos.x -% 1, @intCast(u8, @intCast(i8, pos.y) + dir), color.not(), null)) BB._set(bb, pos.x -% 1, @intCast(u8, @intCast(i8, pos.y) + dir)) else bb;
                bb = if (attack or self._is(pos.x + 1, @intCast(u8, @intCast(i8, pos.y) + dir), color.not(), null)) BB._set(bb, pos.x + 1, @intCast(u8, @intCast(i8, pos.y) + dir)) else bb;
            },
            u.Tag.Rook => {
                bb = self.get_bb_attack_rook(bb, pos, attack);
            },
            u.Tag.Knight => {
                bb = if (attack or !self._is(pos.x + 2, pos.y + 1, color, null)) BB._set(bb, pos.x + 2, pos.y + 1) else bb;
                bb = if (attack or !self._is(pos.x + 1, pos.y + 2, color, null)) BB._set(bb, pos.x + 1, pos.y + 2) else bb;

                bb = if (attack or !self._is(pos.x -% 2, pos.y + 1, color, null)) BB._set(bb, pos.x -% 2, pos.y + 1) else bb;
                bb = if (attack or !self._is(pos.x -% 1, pos.y + 2, color, null)) BB._set(bb, pos.x -% 1, pos.y + 2) else bb;

                bb = if (attack or !self._is(pos.x -% 2, pos.y -% 1, color, null)) BB._set(bb, pos.x -% 2, pos.y -% 1) else bb;
                bb = if (attack or !self._is(pos.x -% 1, pos.y -% 2, color, null)) BB._set(bb, pos.x -% 1, pos.y -% 2) else bb;

                bb = if (attack or !self._is(pos.x + 2, pos.y -% 1, color, null)) BB._set(bb, pos.x + 2, pos.y -% 1) else bb;
                bb = if (attack or !self._is(pos.x + 1, pos.y -% 2, color, null)) BB._set(bb, pos.x + 1, pos.y -% 2) else bb;
            },
            u.Tag.Bishop => {
                bb = self.get_bb_attack_bishop(bb, pos, attack);
            },
            u.Tag.Queen => {
                bb = self.get_bb_attack_rook(bb, pos, attack);
                bb = self.get_bb_attack_bishop(bb, pos, attack);
            },
            u.Tag.King => {
                bb = if (attack or !self._is(pos.x + 1, pos.y, color, null)) BB._set(bb, pos.x + 1, pos.y) else bb;
                bb = if (attack or !self._is(pos.x -% 1, pos.y, color, null)) BB._set(bb, pos.x -% 1, pos.y) else bb;
                bb = if (attack or !self._is(pos.x, pos.y + 1, color, null)) BB._set(bb, pos.x, pos.y + 1) else bb;
                bb = if (attack or !self._is(pos.x, pos.y -% 1, color, null)) BB._set(bb, pos.x, pos.y -% 1) else bb;

                bb = if (attack or !self._is(pos.x + 1, pos.y + 1, color, null)) BB._set(bb, pos.x + 1, pos.y + 1) else bb;
                bb = if (attack or !self._is(pos.x -% 1, pos.y + 1, color, null)) BB._set(bb, pos.x -% 1, pos.y + 1) else bb;
                bb = if (attack or !self._is(pos.x -% 1, pos.y -% 1, color, null)) BB._set(bb, pos.x -% 1, pos.y -% 1) else bb;
                bb = if (attack or !self._is(pos.x + 1, pos.y -% 1, color, null)) BB._set(bb, pos.x + 1, pos.y -% 1) else bb;

                // checking if the RESULT of the move results in checkmate is checked in is_legal
                if (!attack and !self.castle[@enumToInt(color)] and
                    !self.castle[2 + 2 * @intCast(usize, @enumToInt(color))] and
                    self._is(0, pos.y, u.Color.White, u.Tag.Rook) and
                    self._is(1, pos.y, null, null) and
                    self._is(2, pos.y, null, null) and
                    self._is(3, pos.y, null, null))
                {
                    var mboard = self.*;
                    mboard.move(pos, u.Pos.init(pos.x -% 1, pos.y));
                    if (!mboard.is_mate()) {
                        bb = BB._set(bb, pos.x -% 2, pos.y);
                    }
                }
                if (!attack and !self.castle[@enumToInt(color)] and
                    !self.castle[2 + 2 * @intCast(usize, @enumToInt(color)) + 1] and
                    self._is(7, pos.y, u.Color.White, u.Tag.Rook) and
                    self._is(6, pos.y, null, null) and
                    self._is(5, pos.y, null, null))
                {
                    var mboard = self.*;
                    mboard.move(pos, u.Pos.init(pos.x + 1, pos.y));
                    if (!mboard.is_mate()) {
                        bb = BB._set(bb, pos.x + 2, pos.y);
                    }
                }
            },
        }

        return bb;
    }

    fn move(self: *Board, src: u.Pos, dst: u.Pos) void {

        // this function assumes that only possible moves are made, otherwise weird stuff will happen.
        // We can make a lot of assumptions if we assume that the move is guaranteed to be legal
        var val = self.setup[src.to_index()];
        const tag = u.Tag.from_val(val);

        if (tag == u.Tag.Pawn) {
            // handle promition
            // there is no promition to rook, bishop or knight currently
            if (dst.y == 7) {
                val = u.piece_to_val(u.Tag.Queen, u.Color.White);
            }
            if (dst.y == 0) {
                val = u.piece_to_val(u.Tag.Queen, u.Color.Black);
            }

            // handle en passant
            if (tag == u.Tag.Pawn and
                !self.is(dst, null, null))
            {
                self.setup[u.Pos._to_index(dst.x, if (self.active == u.Color.White) dst.y -% 1 else dst.y + 1)] = 15;
            }
        }

        // handle castle
        // there is no weird file castling
        if (tag == u.Tag.King) {
            // Move the "rook"
            if (dst.x == src.x + 2) {
                self.move(u.Pos.init(7, dst.y), u.Pos.init(src.x + 1, dst.y));
            }
            if (src.x == dst.x + 2) {
                self.move(u.Pos.init(0, src.y), u.Pos.init(src.x -% 1, src.y));
            }
        }

        self.setup[dst.to_index()] = val;
        self.setup[src.to_index()] = 15;
    }

    fn is_mate(self: *Board) bool {
        var i: u16 = 0;

        var king_at: ?u16 = null;
        var bb: u64 = 0;
        while (i < 64) : (i += 1) {
            bb = self.get_bb(bb, u.Pos.from_index(i), self.active.not(), true);
            if (self.is(u.Pos.from_index(i), self.active, u.Tag.King)) {
                king_at = i;
            }
        }

        if (king_at != null and BB.in(bb, u.Pos.from_index(king_at.?))) {
            return true;
        }

        return false;
    }

    pub fn is_legal(self: *Board, src: u.Pos, dst: u.Pos) bool {
        const src_val = self.setup[src.to_index()];
        //const src_tag = u.Tag.from_val(src_val);
        const src_color = u.Color.from_val(src_val);

        const dst_val = self.setup[dst.to_index()];
        //const dst_tag = u.Tag.from_val(dst_val);
        const dst_color = u.Color.from_val(dst_val);

        if (src_color != self.active) {
            std.log.info("Invalid color", .{});
            return false;
        }

        if (src_color == dst_color and dst_val != 15) {
            std.log.info("Unable to move same color piece", .{});
            return false;
        }

        var bb: u64 = self.get_bb(0, src, null, false);

        if (!BB.in(bb, dst)) {
            std.log.info("Not in bitboard", .{});
            return false;
        }

        var mboard: Board = self.*;
        mboard.move(src, dst);
        if (mboard.is_mate()) {
            std.log.info("Would be mate", .{});
            return false;
        }

        return true;
    }

    pub fn move_checked(self: *Board, src: u.Pos, dst: u.Pos) void {
        std.log.info("Moving {} to {}", .{ src, dst });

        if (!self.is_legal(src, dst)) {
            std.log.info("Illegal move", .{});
            return;
        }

        self.move(src, dst);

        // check for castling here
        if (u.Tag.from_val(self.setup[src.to_index()]) == u.Tag.King) {
            self.castle[@enumToInt(self.active)] = true;
        }
        if (u.Tag.from_val(self.setup[src.to_index()]) == u.Tag.Rook) {
            switch (src.x * 10 + src.y) {
                0 => {
                    self.castle[2] = true;
                },
                70 => {
                    self.castle[3] = true;
                },
                7 => {
                    self.castle[4] = true;
                },
                77 => {
                    self.castle[5] = true;
                },
                else => {},
            }
        }

        self.active = if (self.active == u.Color.White) u.Color.Black else u.Color.White;

        self.last_move = .{
            .src = src,
            .dst = dst,
        };
    }
};
