pub fn main(init: std.process.Init) !void {
    _ = init;

    const state: lua.State = try .initL();
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
        \\    print("my awesome function")
        \\end
        \\
        \\return 'abc123'
    ;

    const bytecode = lua.compile(code, null);

    if (state.load("=usercode", bytecode, 0)) {
        std.log.err("luau load error: {?s}", .{state.popTopString()});
        return error.LuauLoadError;
    }

    std.heap.c_allocator.free(bytecode);

    const thread = try state.newthread();

    state.pushvalue(-2);
    state.remove(-3);
    state.xmove(thread, 1);

    _ = thread.coResume(.none, 0) catch |err| {
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

const std = @import("std");
const lua = @import("lua");
