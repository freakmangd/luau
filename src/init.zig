pub const c = @import("lua");
pub const State = @import("State.zig");

pub fn compile(source: []const u8, options: ?*c.lua_CompileOptions) []const u8 {
    var out_len: usize = 0;
    const bytecode = c.luau_compile(source.ptr, source.len, options, &out_len);
    return bytecode[0..out_len];
}

pub inline fn errwrap(lua_err: c_int) (Error || CoroutineError)!void {
    if (lua_err == 0) return;

    return switch (lua_err) {
        c.LUA_YIELD => error.LuaYield,
        c.LUA_ERRRUN => error.LuaErrRun,
        c.LUA_ERRSYNTAX => error.LuaErrSyntax,
        c.LUA_ERRMEM => error.LuaErrMem,
        c.LUA_ERRERR => error.LuaErrErr,
        c.LUA_BREAK => error.LuaBreak,
        else => unreachable,
    };
}

pub const Ref = enum(c_int) {
    noref = -1,
    refnil = 0,
    _,

    pub fn hasRef(ref: Ref) bool {
        return ref != .noref and ref != .refnil;
    }
};

pub const Status = enum(c_int) {
    ok = c.LUA_OK,
    yield = c.LUA_YIELD,
    errrun = c.LUA_ERRRUN,
    errsyntax = c.LUA_ERRSYNTAX,
    errmem = c.LUA_ERRMEM,
    errerr = c.LUA_ERRERR,
    @"break" = c.LUA_BREAK,
};

pub const CoroutineStatus = enum(c_int) {
    ok = c.LUA_OK,
    yield = c.LUA_YIELD,
    @"break" = c.LUA_BREAK,
};

pub const CoroutineError = error{
    LuaYield,
    LuaBreak,
};

pub const Error = error{
    LuaErrRun,
    LuaErrSyntax,
    LuaErrMem,
    LuaErrErr,
};

pub const Type = enum(c_int) {
    nil = c.LUA_TNIL,
    boolean = c.LUA_TBOOLEAN,
    lightuserdata = c.LUA_TLIGHTUSERDATA,
    number = c.LUA_TNUMBER,
    integer = c.LUA_TINTEGER,
    vector = c.LUA_TVECTOR,
    string = c.LUA_TSTRING,
    table = c.LUA_TTABLE,
    function = c.LUA_TFUNCTION,
    userdata = c.LUA_TUSERDATA,
    thread = c.LUA_TTHREAD,
    buffer = c.LUA_TBUFFER,
    class = c.LUA_TCLASS,
    object = c.LUA_TOBJECT,
    deadkey = c.LUA_TDEADKEY,
    proto = c.LUA_TPROTO,
    upval = c.LUA_TUPVAL,

    pub const _count: Type = .deadkey;

    pub fn int(t: Type) c_int {
        return @backingInt(t);
    }
};

pub const GcOp = enum(c_int) {
    stop = c.LUA_GCSTOP,
    restart = c.LUA_GCRESTART,
    collect = c.LUA_GCCOLLECT,
    count = c.LUA_GCCOUNT,
    countb = c.LUA_GCCOUNTB,
    isrunning = c.LUA_GCISRUNNING,
    step = c.LUA_GCSTEP,
    setgoal = c.LUA_GCSETGOAL,
    setstepmul = c.LUA_GCSETSTEPMUL,
    setstepsize = c.LUA_GCSETSTEPSIZE,
};

pub const multret = c.LUA_MULTRET;
pub const minstack = c.LUA_MINSTACK;
pub const registryindex = c.LUA_REGISTRYINDEX;

pub const ok = c.LUA_OK;
pub const yield = c.LUA_YIELD;
pub const @"break" = c.LUA_BREAK;
pub const errrun = c.LUA_ERRRUN;
pub const errsyntax = c.LUA_ERRSYNTAX;
pub const errmem = c.LUA_ERRMEM;
pub const errerr = c.LUA_ERRERR;

pub const Debug = c.lua_Debug;
pub const Callbacks = c.lua_Callbacks;
pub const CompileOptions = c.lua_CompileOptions;
pub const Reg = c.luaL_Reg;
pub const Alloc = c.lua_Alloc;
pub const CFunction = c.lua_CFunction;
pub const Integer = c.lua_Integer;
pub const Number = c.lua_Number;

test {
    _ = State;
}
