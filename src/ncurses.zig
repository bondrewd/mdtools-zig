const std = @import("std");
const c = @cImport(@cInclude("ncurses.h"));

pub const Window = ?*c.WINDOW;

pub const key_down = 402;
pub const key_up = 403;
pub const key_left = 404;
pub const key_right = 405;

pub const NCursesError = error{
    FailedToRefreshWindow,
    FailedToCreateWindow,
    FailedToDrawBox,
    FailedToMoveCursor,
    FailedToAddChar,
    FailedToAddString,
    FailedToTurnOnEcho,
    FailedToTurnOffEcho,
};

pub fn initStdWindow() Window {
    return c.initscr();
}

pub fn deinitStdWindow() void {
    const err_code = c.endwin();
    if (err_code != 0) std.debug.panic("Failed to deinit std screen.", .{});
}

pub fn winRefresh(window: Window) NCursesError!void {
    const err_code = c.wrefresh(window);
    if (err_code != 0) return error.FailedToRefreshWindow;
}

pub fn refresh() NCursesError!void {
    try winRefresh(c.stdscr);
}

pub fn winGetMaxX(window: Window) u32 {
    return @intCast(u32, c.getmaxx(window));
}

pub fn getMaxX() u32 {
    return winGetMaxX(c.stdscr);
}

pub fn winGetMaxY(window: Window) u32 {
    return @intCast(u32, c.getmaxy(window));
}

pub fn getMaxY() u32 {
    return winGetMaxY(c.stdscr);
}

pub fn createWindow(cols: u32, rows: u32, ori_x: u32, ori_y: u32) NCursesError!Window {
    var new_window: ?Window = c.newwin(@intCast(c_int, rows), @intCast(c_int, cols), @intCast(c_int, ori_y), @intCast(c_int, ori_x));
    return new_window orelse error.FailedToCreateWindow;
}

pub fn destroyWindow(window: Window) void {
    const err_code = c.delwin(window);
    if (err_code != 0) std.debug.panic("Failed to destroy window.", .{});
}

pub fn winBox(window: Window, h_char: u32, v_char: u32) NCursesError!void {
    const err_code = c.box(window, h_char, v_char);
    if (err_code != 0) return error.FailedToDrawBox;
}

pub fn winMove(window: Window, x: u32, y: u32) NCursesError!void {
    const err_code = c.wmove(window, @intCast(c_int, y), @intCast(c_int, x));
    if (err_code != 0) return error.FailedToMoveCursor;
}

pub fn move(x: u32, y: u32) NCursesError!void {
    try winMove(c.stdscr, x, y);
}

pub fn winGetChar(window: Window) u32 {
    return @intCast(u32, c.wgetch(window));
}

pub fn getChar() u32 {
    return winGetChar(c.stdscr);
}

pub fn winAddChar(window: Window, char: u32) NCursesError!void {
    const err_code = c.waddch(window, char);
    if (err_code != 0) return error.FailedToAddChar;
}

pub fn addChar(char: u32) NCursesError!void {
    try winAddChar(c.stdscr, char);
}

pub fn winMoveAddChar(window: Window, x: u32, y: u32, char: u32) NCursesError!void {
    try winMove(window, x, y);
    try winAddChar(window, char);
}

pub fn moveAddChar(x: u32, y: u32, char: u32) NCursesError!void {
    try winMove(c.stdscr, x, y);
    try winAddChar(c.stdscr, char);
}

pub fn winAddStr(window: Window, str: []const u8) NCursesError!void {
    const err_code = c.waddnstr(window, @ptrCast([*c]const u8, str), @intCast(c_int, str.len));
    if (err_code != 0) return error.FailedToAddString;
}

pub fn addStr(str: []const u8) NCursesError!void {
    try winAddStr(c.stdscr, str);
}

pub fn winMoveAddStr(window: Window, x: u32, y: u32, str: []const u8) NCursesError!void {
    try winMove(window, x, y);
    try winAddStr(window, str);
}

pub fn moveAddStr(x: u32, y: u32, str: []const u8) NCursesError!void {
    try winMove(c.stdscr, x, y);
    try winAddStr(c.stdscr, str);
}

pub fn turnOnEcho() NCursesError!void {
    const err_code = c.echo();
    if (err_code != 0) return error.FailedToTurnOnEcho;
}

pub fn turnOffEcho() NCursesError!void {
    const err_code = c.noecho();
    if (err_code != 0) return error.FailedToTurnOffEcho;
}
