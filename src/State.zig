//! On [-o, +p, x] notes:
//!
//! The first field, o, is how many elements the function pops from the stack.
//! The second field, p, is how many elements the function pushes onto the stack.
//! (Any function always pushes its results after popping its arguments.)
//!
//! A field in the form x|y means the function can push (or pop) x or y elements, depending on the situation;
//! an interrogation mark '?' means that we cannot know how many elements the function pops/pushes by looking
//! only at its arguments (e.g., they may depend on what is on the stack).
//!
//! The third field, x, tells whether the function may throw errors: '-' means the function never throws any error;
//!   'm' means the function may throw an error only due to not enough memory;
//!   'e' means the function may throw other kinds of errors;
//!   'v' means the function may throw an error on purpose.

const State = @This();

c_state: ?*c.lua_State,

pub const none: State = .{ .c_state = null };

pub fn init(f: lua.Alloc, ud: ?*anyopaque) std.mem.Allocator.Error!State {
    return .{ .c_state = c.lua_newstate(f, ud) orelse return error.OutOfMemory };
}

pub fn initL() std.mem.Allocator.Error!State {
    return .{ .c_state = c.luaL_newstate() orelse return error.OutOfMemory };
}

pub fn deinit(s: State) void {
    c.lua_close(s.c_state);
}

fn autoConvert(s: State, T: type, idx: c_int) T {
    return switch (@typeInfo(T)) {
        .float => @floatCast(s.tonumber(idx)),
        .int => @intCast(s.tointeger(idx)),
        .bool => s.toboolean(idx),
        .pointer => switch (T) {
            ?[]const u8, ?[:0]const u8 => s.tolstring(idx),
            ?[*]const u8, [*:0]const u8 => s.tostring(idx),
            ?*const anyopaque => s.topointer(idx),
            else => @compileError("type " ++ @typeName(T) ++ " cannot be simply converted"),
        },
        else => @compileError("type " ++ @typeName(T) ++ " cannot be simply converted"),
    };
}

pub fn wrap(c_state: ?*c.lua_State) State {
    return .{ .c_state = c_state };
}

pub fn absindex(s: State, idx: c_int) c_int {
    return c.lua_absindex(s.c_state, idx);
}

/// [-(nargs + 1), +nresults, e]
pub fn call(s: State, nargs: c_int, nresults: c_int) void {
    c.lua_call(s.c_state, nargs, nresults);
}

/// [0, 0, -]
pub fn callbacks(s: State) *lua.Callbacks {
    return c.lua_callbacks(s.c_state);
}

/// [-n, +1, e]
pub fn concat(s: State, n: c_int) void {
    c.lua_concat(s.c_state, n);
}

/// [-0, +(0|1), -]
pub fn cpcall(s: State, func: lua.CFunction, ud: ?*anyopaque) PcallError!void {
    lua.errwrap(c.lua_cpcall(s.c_state, func, ud)) catch |err| {
        return @errorCast(err);
    };
}

/// [-0, +1, m]
pub fn createtable(s: State, narr: c_int, nrec: c_int) void {
    c.lua_createtable(s.c_state, narr, nrec);
}

/// [-0, +0, e]
pub fn equal(s: State, index1: c_int, index2: c_int) bool {
    return c.lua_equal(s.c_state, index1, index2) != 0;
}

/// [-1, +0, v]
pub fn luaError(s: State) noreturn {
    c.lua_error(s.c_state);
}

/// [-0, +0, e]
pub fn gc(s: State, what: lua.GcOp, data: c_int) lua.GcOp {
    return @fromBackingInt(@intCast(c.lua_gc(s.c_state, @backingInt(what), data)));
}

/// [-0, +0, -]
pub fn getallocf(s: State, ud: ?*?*anyopaque) lua.Alloc {
    return c.lua_getallocf(s.c_state, ud);
}

/// [-0, +1, -]
pub fn getfenv(s: State, idx: c_int) void {
    c.lua_getfenv(s.c_state, idx);
}

/// [-0, +1, e]
pub fn getfield(s: State, idx: c_int, name: [*:0]const u8) lua.Type {
    return @fromBackingInt(@intCast(c.lua_getfield(s.c_state, idx, name)));
}

/// [-0, +1, e]
pub fn getfieldAs(s: State, T: type, idx: c_int, name: [*:0]const u8) T {
    _ = s.getfield(idx, name);
    return s.autoConvert(T, -1);
}

/// [-0, +1, e]
pub fn getglobal(s: State, name: [*:0]const u8) lua.Type {
    return @fromBackingInt(@intCast(c.lua_getglobal(s.c_state, name)));
}

/// [-0, +(0|1), -]
pub fn getmetatable(s: State, idx: c_int) bool {
    return c.lua_getmetatable(s.c_state, idx) != 0;
}

/// [-0, +(0|1), -]
pub fn getmetatableL(s: State, name: [*:0]const u8) lua.Type {
    return @fromBackingInt(@intCast(c.luaL_getmetatable(s.c_state, name)));
}

/// [-0, +1, -]
pub fn getref(s: State, r: lua.Ref) lua.Type {
    return @fromBackingInt(@intCast(c.lua_rawgeti(s.c_state, lua.registryindex, @backingInt(r))));
}

/// [-1, +1, e]
pub fn gettable(s: State, idx: c_int) lua.Type {
    return @fromBackingInt(@intCast(c.lua_gettable(s.c_state, idx)));
}

/// [-0, +0, -]
pub fn gettop(s: State) c_int {
    return c.lua_gettop(s.c_state);
}

/// [-1, +1, -]
pub fn insert(s: State, idx: c_int) void {
    c.lua_insert(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isboolean(s: State, idx: c_int) bool {
    return c.lua_isboolean(s.c_state, idx);
}

/// [-0, +0, -]
pub fn iscfunction(s: State, idx: c_int) bool {
    return c.lua_iscfunction(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isinteger64(s: State, idx: c_int) bool {
    return c.lua_isinteger64(s.c_state, idx);
}

/// [-0, +0, -]
pub fn islightuserdata(s: State, idx: c_int) bool {
    return c.lua_islightuserdata(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isnil(s: State, idx: c_int) bool {
    return c.lua_isnil(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isnone(s: State, idx: c_int) bool {
    return c.lua_isnone(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isnoneornil(s: State, idx: c_int) bool {
    return c.lua_isnoneornil(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isnumber(s: State, idx: c_int) bool {
    return c.lua_isnumber(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isstring(s: State, idx: c_int) bool {
    return c.lua_isstring(s.c_state, idx);
}

/// [-0, +0, -]
pub fn istable(s: State, idx: c_int) bool {
    return c.lua_istable(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isthread(s: State, idx: c_int) bool {
    return c.lua_isthread(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isuserdata(s: State, idx: c_int) bool {
    return c.lua_isuserdata(s.c_state, idx);
}

/// [-0, +0, -]
pub fn isyieldable(s: State) bool {
    return c.lua_isyieldable(s.c_state) != 0;
}

/// [-0, +0, e]
pub fn lessthan(s: State, idx1: c_int, idx2: c_int) bool {
    return c.lua_lessthan(s.c_state, idx1, idx2);
}

pub const LoadError = error{
    LuaErrSyntax,
    LuaErrMem,
};

/// [-0, +1, -]
pub fn load(s: State, chunkname: [*:0]const u8, bytecode: []const u8, env: c_int) bool {
    return c.luau_load(s.c_state, chunkname, bytecode.ptr, bytecode.len, env) != 0;
}

/// [-0, +1, -]
pub fn newtable(s: State) void {
    c.lua_newtable(s.c_state);
}

/// [-0, +1, m]
pub fn newthread(s: State) std.mem.Allocator.Error!State {
    return .{ .c_state = c.lua_newthread(s.c_state) orelse return error.OutOfMemory };
}

/// [-0, +1, m]
pub fn newuserdata(s: State, size: usize) ?*anyopaque {
    return c.lua_newuserdata(s.c_state, size);
}

/// [-0, +1, m]
pub fn newuserdataAs(s: State, T: type) ?*T {
    const ptr = c.lua_newuserdata(s.c_state, @sizeOf(T)) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

/// [-0, +1, m]
pub fn newuserdatadtor(s: State, size: usize, dtor: *const fn (?*anyopaque) callconv(.c) void) ?*anyopaque {
    return c.lua_newuserdatadtor(s.c_state, size, dtor);
}

/// [-0, +1, m]
pub fn newuserdatadtorAs(s: State, T: type, comptime dtor: *const fn (*T) void) ?*T {
    const ptr = c.lua_newuserdatadtor(s.c_state, @sizeOf(T), struct {
        fn f(ptr: ?*anyopaque) callconv(.c) void {
            dtor(@ptrCast(@alignCast(ptr)));
        }
    }.f) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

/// [-0, +1, m]
pub fn newuserdatatagged(s: State, size: usize, tag: c_int) ?*anyopaque {
    return c.lua_newuserdatatagged(s.c_state, size, tag);
}

/// [-0, +1, m]
pub fn newuserdatataggedAs(s: State, T: type, tag: c_int) ?*T {
    const ptr = c.lua_newuserdatatagged(s.c_state, @sizeOf(T), tag) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

/// [-1, +(2|0), e]
pub fn next(s: State, idx: c_int) bool {
    return c.lua_next(s.c_state, idx) != 0;
}

/// [-0, +0, -]
pub fn objlen(s: State, idx: c_int) c_int {
    return c.lua_objlen(s.c_state, idx);
}

/// [-0, +0, -]
pub fn objlenU(s: State, idx: c_int) usize {
    return @intCast(c.lua_objlen(s.c_state, idx));
}

pub const PcallError = error{
    LuaErrRun,
    LuaErrMem,
    LuaErrErr,
};

/// [-(nargs + 1), +(nresults|1), -]
pub fn pcall(s: State, nargs: c_int, nresults: c_int, errfunc: c_int) PcallError!void {
    return switch (c.lua_pcall(s.c_state, nargs, nresults, errfunc)) {
        lua.ok => {},
        lua.errrun => error.LuaErrRun,
        lua.errmem => error.LuaErrMem,
        lua.errerr => error.LuaErrErr,
        else => unreachable,
    };
}

/// [-n, +0, -]
pub fn pop(s: State, n: c_int) void {
    c.lua_pop(s.c_state, n);
}

/// [-0, +1, -]
pub fn pushboolean(s: State, b: bool) void {
    c.lua_pushboolean(s.c_state, @intFromBool(b));
}

/// [-n, +1, m]
pub fn pushcclosure(s: State, comptime func: WrappedFunc, debugname: [*:0]const u8, n: c_int) void {
    c.lua_pushcclosure(s.c_state, wrapStateFunc(func), debugname, n);
}

/// [-0, +1, m]
pub fn pushcfunction(s: State, comptime func: WrappedFunc, debugname: [*:0]const u8) void {
    c.lua_pushcclosurek(s.c_state, wrapStateFunc(func), debugname, 0, null);
}

/// [-0, +1, -]
pub fn pushinteger(s: State, n: lua.Integer) void {
    c.lua_pushinteger(s.c_state, n);
}

/// [-0, +1, -]
pub fn pushlightuserdata(s: State, p: ?*anyopaque) void {
    c.lua_pushlightuserdata(s.c_state, p);
}

/// [-0, +1, m]
pub fn pushliteral(s: State, comptime str: []const u8) [*:0]const u8 {
    return c.lua_pushliteral(s.c_state, str);
}

/// [-0, +1, m]
pub fn pushlstring(s: State, str: []const u8) void {
    c.lua_pushlstring(s.c_state, str.ptr, str.len);
}

/// [-0, +1, -]
pub fn pushnil(s: State) void {
    c.lua_pushnil(s.c_state);
}

/// [-0, +1, -]
pub fn pushnumber(s: State, n: f64) void {
    c.lua_pushnumber(s.c_state, n);
}

/// [-0, +1, m]
pub fn pushstring(s: State, str: [*:0]const u8) void {
    c.lua_pushstring(s.c_state, str);
}

/// [-0, +1, -]
pub fn pushthread(s: State) bool {
    return c.lua_pushthread(s.c_state) != 0;
}

/// [-0, +1, -]
pub fn pushvalue(s: State, idx: c_int) void {
    c.lua_pushvalue(s.c_state, idx);
}

/// [-0, +0, -]
pub fn rawequal(s: State, idx1: c_int, idx2: c_int) bool {
    return c.lua_rawequal(s.c_state, idx1, idx2) != 0;
}

/// [-1, +1, -]
pub fn rawget(s: State, idx: c_int) void {
    c.lua_rawget(s.c_state, idx);
}

/// [-0, +1, -]
pub fn rawgeti(s: State, idx: c_int, n: c_int) lua.Type {
    return @fromBackingInt(@intCast(c.lua_rawgeti(s.c_state, idx, n)));
}

/// [-0, +1, -]
pub fn rawgetiAs(s: State, T: type, idx: c_int, n: c_int) T {
    _ = s.rawgeti(idx, n);
    return s.autoConvert(T, -1);
}

/// [-2, +0, m]
pub fn rawset(s: State, idx: c_int) void {
    c.lua_rawset(s.c_state, idx);
}

/// [-1, +0, m]
pub fn rawseti(s: State, idx: c_int, n: c_int) void {
    c.lua_rawseti(s.c_state, idx, n);
}

/// [-0, +0, m]
pub fn ref(s: State, idx: c_int) lua.Ref {
    return @fromBackingInt(@intCast(c.lua_ref(s.c_state, idx)));
}

const WrappedReg = struct {
    name: [*:0]const u8,
    func: *const fn (State) anyerror!c_int,
};

/// [-0, +0, e]
pub fn registerLSlice(s: State, name: ?[*:0]const u8, comptime l: []const WrappedReg) void {
    const l_c: [*]const lua.Reg = comptime l_c: {
        var l_c: [l.len + 1]lua.Reg = undefined;

        for (l, l_c[0..l.len]) |r, *r_c| {
            r_c.* = .{
                .name = r.name,
                .func = wrapStateFunc(r.func),
            };
        }

        l_c[l.len] = .{ .name = null, .func = null };

        const l_c_const = l_c;
        break :l_c &l_c_const;
    };

    c.luaL_register(s.c_state, name, l_c);
}

/// [-0, +0, e]
pub fn registerL(s: State, name: ?[*:0]const u8, l: [*]const lua.Reg) void {
    c.luaL_register(s.c_state, name, l);
}

/// [-1, +0, -]
pub fn remove(s: State, idx: c_int) void {
    c.lua_remove(s.c_state, idx);
}

/// [-1, +0, -]
pub fn replace(s: State, idx: c_int) void {
    c.lua_replace(s.c_state, idx);
}

pub fn resetthread(s: State) void {
    c.lua_resetthread(s.c_state);
}

/// [-?, +?, -]
pub fn coResume(s: State, from: State, narg: c_int) PcallError!lua.CoroutineStatus {
    return switch (c.lua_resume(s.c_state, from.c_state, narg)) {
        lua.ok => .ok,
        lua.yield => .yield,
        lua.@"break" => .@"break",
        lua.errrun => error.LuaErrRun,
        lua.errmem => error.LuaErrMem,
        lua.errerr => error.LuaErrErr,
        else => unreachable,
    };
}

pub fn sandbox(s: State) void {
    c.luaL_sandbox(s.c_state);
}

pub fn sandboxthread(s: State) void {
    c.luaL_sandboxthread(s.c_state);
}

/// [-1, +0, -]
pub fn setfenv(s: State, idx: c_int) bool {
    return c.lua_setfenv(s.c_state, idx) != 0;
}

/// [-1, +0, e]
pub fn setfield(s: State, idx: c_int, name: [*:0]const u8) void {
    c.lua_setfield(s.c_state, idx, name);
}

/// [-1, +0, e]
pub fn setglobal(s: State, name: [*:0]const u8) void {
    c.lua_setglobal(s.c_state, name);
}

/// [-1, +0, -]
pub fn setmetatable(s: State, idx: c_int) c_int {
    return c.lua_setmetatable(s.c_state, idx);
}

/// [-2, +0, e]
pub fn settable(s: State, idx: c_int) void {
    c.lua_settable(s.c_state, idx);
}

/// [-?, +?, -]
pub fn settop(s: State, idx: c_int) void {
    c.lua_settop(s.c_state, idx);
}

pub fn setuserdatadtor(s: State, tag: c_int, comptime dtor: *const fn (State, *anyopaque) void) void {
    c.lua_setuserdatadtor(s.c_state, tag, struct {
        fn f(c_state: ?*c.lua_State, ptr: ?*anyopaque) callconv(.c) void {
            dtor(.wrap(c_state), @ptrCast(ptr));
        }
    }.f);
}

/// [-0, +0, -]
pub fn status(s: State) lua.Status {
    return @fromBackingInt(@intCast(c.lua_status(s.c_state)));
}

/// [-0, +0, -]
pub fn toboolean(s: State, idx: c_int) bool {
    return c.lua_toboolean(s.c_state, idx) != 0;
}

/// [-0, +0, -]
pub fn tocfunction(s: State, idx: c_int) lua.CFunction {
    return c.lua_tocfunction(s.c_state, idx);
}

/// [-0, +0, -]
pub fn tointeger(s: State, idx: c_int) lua.Integer {
    return c.lua_tointegerx(s.c_state, idx, null);
}

/// [-0, +0, m]
pub fn tolstring(s: State, idx: c_int) ?[:0]const u8 {
    var len: usize = 0;
    const msg = c.lua_tolstring(s.c_state, idx, &len) orelse return null;
    return msg[0..len :0];
}

/// [-0, +0, m]
pub fn tolstringL(s: State, idx: c_int) ?[:0]const u8 {
    var len: usize = 0;
    const msg = c.luaL_tolstring(s.c_state, idx, &len) orelse return null;
    return msg[0..len :0];
}

/// [-0, +0, -]
pub fn tonumber(s: State, idx: c_int) lua.Number {
    return c.lua_tonumberx(s.c_state, idx, null);
}

/// [-0, +0, -]
pub fn topointer(s: State, idx: c_int) ?*const anyopaque {
    return c.lua_topointer(s.c_state, idx);
}

/// [-0, +0, m]
pub fn tostring(s: State, idx: c_int) ?[*:0]const u8 {
    return c.lua_tolstring(s.c_state, idx, null);
}

/// [-0, +0, -]
pub fn tothread(s: State, idx: c_int) State {
    return .{ .c_state = c.lua_tothread(s.c_state, idx) };
}

/// [-0, +0, -]
pub fn touserdata(s: State, idx: c_int) ?*anyopaque {
    return c.lua_touserdata(s.c_state, idx);
}

/// [-0, +0, -]
pub fn touserdataAs(s: State, T: type, idx: c_int) ?*T {
    const ptr = c.lua_touserdata(s.c_state, idx) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

/// [-0, +0, -]
pub fn luaType(s: State, idx: c_int) lua.Type {
    return @fromBackingInt(@intCast(c.lua_type(s.c_state, idx)));
}

/// [-0, +0, -]
pub fn typename(s: State, tp: lua.Type) ?[*:0]const u8 {
    return c.lua_typename(s.c_state, @backingInt(tp));
}

/// [-0, +0, -]
pub fn typenameL(s: State, idx: c_int) ?[*:0]const u8 {
    return c.luaL_typename(s.c_state, idx);
}

pub fn unref(s: State, r: lua.Ref) void {
    c.lua_unref(s.c_state, @backingInt(r));
}

/// [-0, +0, -]
pub fn userdatatag(s: State, idx: c_int) c_int {
    return c.lua_userdatatag(s.c_state, idx);
}

/// [-0, +0, -]
pub fn userdatatagAs(s: State, Tag: type, idx: c_int) ?Tag {
    const tag = c.lua_userdatatag(s.c_state, idx);
    if (tag == -1) return null;
    return @fromBackingInt(@intCast(tag));
}

/// [-?, +?, -]
pub fn xmove(from: State, to: State, n: c_int) void {
    c.lua_xmove(from.c_state, to.c_state, n);
}

pub fn xpush(from: State, to: State, idx: c_int) void {
    c.lua_xpush(from.c_state, to.c_state, idx);
}

/// [-?, +?, e]
pub fn yield(s: State, nresults: c_int) c_int {
    return c.lua_yield(s.c_state, nresults);
}

/// [-0, +0, v]
pub fn checkany(s: State, narg: c_int) void {
    c.luaL_checkany(s.c_state, narg);
}

pub fn checkboolean(s: State, narg: c_int) bool {
    return c.luaL_checkboolean(s.c_state, narg) != 0;
}

/// [-0, +0, v]
pub fn checkinteger(s: State, narg: c_int) lua.Integer {
    return c.luaL_checkinteger(s.c_state, narg);
}

/// [-0, +0, v]
pub fn checklstring(s: State, narg: c_int) ?[:0]const u8 {
    var len: usize = 0;
    const str = c.luaL_checklstring(s.c_state, narg, &len) orelse return null;
    return str[0..len :0];
}

/// [-0, +0, v]
pub fn checknumber(s: State, narg: c_int) f64 {
    return c.luaL_checknumber(s.c_state, narg);
}

/// [-0, +0, v]
pub fn checkoption(s: State, narg: c_int, def: ?[*:0]const u8, lst: ?[*:null]const ?[*:0]const u8) c_int {
    return c.luaL_checkoption(s.c_state, narg, def, lst);
}

/// [-0, +0, v]
pub fn checkstack(s: State, sz: c_int, msg: [*:0]const u8) void {
    c.luaL_checkstack(s.c_state, sz, msg);
}

/// [-0, +0, v]
pub fn checkstring(s: State, arg: c_int) ?[*:0]const u8 {
    return c.luaL_checklstring(s.c_state, arg, null);
}

/// [-0, +0, v]
pub fn checktype(s: State, arg: c_int, t: lua.Type) void {
    return c.luaL_checktype(s.c_state, arg, t.int());
}

/// [-0, +0, v]
pub fn checkudata(s: State, arg: c_int, tname: [*:0]const u8) ?*anyopaque {
    return c.luaL_checkudata(s.c_state, arg, tname);
}

/// [-0, +0, v]
pub fn checkudataAs(s: State, T: type, arg: c_int, tname: [*:0]const u8) ?*T {
    const ptr = c.luaL_checkudata(s.c_state, arg, tname) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

/// [-0, +1, m]
pub fn newmetatable(s: State, tname: [*:0]const u8) bool {
    return c.luaL_newmetatable(s.c_state, tname) != 0;
}

/// [-0, +0, e]
pub fn opt(s: State, T: type, comptime func: *const fn (State, c_int) T, arg: c_int, dflt: T) T {
    return c.luaL_opt(s.c_state, struct {
        fn f(c_state: ?*c.lua_State, idx: c_int) T {
            return func(.wrap(c_state), idx);
        }
    }.f, arg, dflt);
}

/// [-0, +0, v]
pub fn optinteger(s: State, arg: c_int, def: lua.Integer) lua.Integer {
    return c.luaL_optinteger(s.c_state, arg, def);
}

/// [-0, +0, v]
pub fn optlstring(s: State, arg: c_int, def: [*:0]const u8) [:0]const u8 {
    var len: usize = 0;
    const str = c.luaL_optlstring(s.c_state, arg, def, &len);
    return str[0..len :0];
}

/// [-0, +0, v]
pub fn optnumber(s: State, arg: c_int, def: lua.Number) lua.Number {
    return c.luaL_optnumber(s.c_state, arg, def);
}

/// [-0, +0, e]
pub fn openlibs(s: State) void {
    c.luaL_openlibs(s.c_state);
}

pub fn popTopString(s: State) ?[:0]const u8 {
    const msg = s.tolstring(-1);
    s.pop(1);
    return msg;
}

pub fn logStackBacktrace(s: State, err_status: lua.Error, w: *Io.Writer) !void {
    var ar: c.lua_Debug = undefined;
    if (c.lua_getinfo(s.c_state, 0, "sln", &ar) != 0) {
        try w.print("{s}: ", .{ar.short_src});
    }

    if (err_status == error.LuaYield) {
        try w.print("thread yielded unexpectedly", .{});
    } else maybe_str: {
        const str = s.tolstring(-1) orelse break :maybe_str;
        try w.print("lua error: {s}", .{str});
    }

    try w.print("\nlua stack backtrace:\n", .{});
    try w.print("{s}", .{c.lua_debugtrace(s.c_state)});
}

/// [-0, +0, m]
pub fn debugStack(s: State) void {
    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer);
    defer std.debug.unlockStderr();
    writeStack(s, &stderr.file_writer.interface) catch return;
}

/// [-0, +0, m]
pub fn writeStack(s: State, w: *Io.Writer) !void {
    const top = s.gettop();
    try w.print("lua stack (top={}):\n", .{top});

    for (1..@intCast(top + 1)) |_i| {
        const i: c_int = @intCast(_i);
        try w.print("  [{}] {f}\n", .{ i, s.fmt(i) });
    }
}

/// [-0, +0, e]
pub fn debugTable(s: State, idx: c_int) void {
    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer);
    defer std.debug.unlockStderr();
    writeTable(s, idx, &stderr.file_writer.interface) catch return;
}

/// [-0, +0, e]
pub fn writeTable(s: State, idx: c_int, w: *Io.Writer) !void {
    const table_idx = s.absindex(idx);
    try w.print("{f}\n", .{s.fmt(table_idx)});
}

const StackValueFmt = struct {
    state: State,
    idx: c_int,
    max_depth: usize = 3,

    pub fn format(self: @This(), w: *std.Io.Writer) !void {
        try self.formatInner(w, self.idx, 0);
    }

    fn formatInner(self: @This(), w: *std.Io.Writer, i: c_int, depth: usize) !void {
        const s = self.state;
        const i_abs = s.absindex(i);
        const t = s.luaType(i_abs);

        switch (t) {
            .string => try w.print("{?q}", .{s.tolstring(i_abs)}),
            .boolean => try w.print("{}", .{s.toboolean(i_abs)}),
            .number => try w.print("{d}", .{s.tonumber(i_abs)}),
            .nil => try w.writeAll("nil"),
            .table => {
                if (depth < self.max_depth) {
                    try w.print("table: {*} = {{", .{s.topointer(i_abs)});

                    var has_fields = false;

                    s.pushnil();
                    while (s.next(i_abs)) {
                        defer s.pop(1);
                        has_fields = true;
                        try w.print("\n  [{f}] {t} = ", .{ s.fmt(-2), s.luaType(-1) });
                        try self.formatInner(w, -1, depth + 1);
                        try w.writeByte(',');
                    }

                    if (has_fields) {
                        try w.writeByte('\n');
                    }

                    try w.writeAll("}");
                } else {
                    try w.print("table: {*}", .{s.topointer(i)});
                }
            },
            .function => try w.print("function: {*}", .{s.topointer(i_abs)}),
            .userdata => {
                if (s.tolstringL(i_abs)) |as_str| {
                    defer s.pop(1);
                    try w.print("userdata: '{s}'", .{as_str});
                } else {
                    try w.print("userdata: {*}", .{s.topointer(i_abs)});
                }
            },
            .lightuserdata => try w.print("lightuserdata: {*}", .{s.touserdata(i_abs)}),
            else => try w.print("{?s}: {*}", .{ s.typename(t), s.touserdata(i_abs) }),
        }
    }
};

pub fn fmt(s: State, idx: c_int) StackValueFmt {
    return .{ .state = s, .idx = idx };
}

pub fn fmtShort(s: State, idx: c_int) StackValueFmt {
    return .{ .state = s, .idx = idx, .max_depth = 0 };
}

const WrappedFunc = *const fn (State) anyerror!c_int;

fn wrapStateFunc(comptime func: WrappedFunc) *const fn (?*c.lua_State) callconv(.c) c_int {
    return struct {
        fn f(s: ?*c.lua_State) callconv(.c) c_int {
            return func(.wrap(s)) catch |err|
                return c.luaL_errorL(s, "internal error: %s", @errorName(err).ptr);
        }
    }.f;
}

test State {
    const state: State = try .init();
    defer state.deinit();

    state.openlibs();
    state.sandbox();
    state.sandboxthread();

    const code =
        \\local a = {}
        \\a.msg = "DEADBEEF"
        \\print(a, a.msg)
        \\
        \\function runme()
        \\    print("my awesome c function: ", add(2, 3))
        \\end
    ;

    const bytecode = lua.compile(code, null);
    defer std.heap.c_allocator.free(bytecode);

    state.load("=usercode", bytecode, 0) catch |err| {
        std.log.err("{}: {s}", .{ err, state.popTopString() });
        return err;
    };

    const thread = try state.newthread();

    state.pushvalue(-2);
    state.remove(-3);
    state.xmove(thread, 1);

    state.pushcfunction(c_add, "add");
    state.setglobal("add");

    thread.coResume(.none, 0) catch |err| {
        defer std.debug.unlockStderr();
        thread.logStackBacktrace(err, &std.debug.lockStderr(&.{}).file_writer.interface) catch |e|
            std.log.err("couldn't log backtrace: {}", .{e});
        state.pop(1);

        return err;
    };

    _ = thread.getglobal("runme");

    if (thread.isnil(-1)) {
        thread.pop(1);
    } else {
        try thread.pcall(0, 0, 0);
    }

    const n = thread.gettop();

    if (n != 0) {
        thread.checkstack(lua.minstack, "too many results to print");
        _ = thread.getglobal("print");
        thread.insert(1);
        try thread.pcall(n, 0, 0);
    }

    state.pop(1);
}

fn c_add(state: State) c_int {
    const a = state.checknumber(1);
    const b = state.checknumber(2);
    state.pushnumber(a + b);
    return 1;
}

const std = @import("std");
const Io = std.Io;
const lua = @import("init.zig");
const c = @import("lua");
