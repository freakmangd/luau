const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const luau_dep = b.dependency("luau", .{
        .target = target,
        .optimize = optimize,
    });

    const options: Options = .{
        .target = target,
        .optimize = optimize,
        .luau_dep = luau_dep,
    };

    const mod = b.addModule("luau", .{
        .root_source_file = b.path("src/init.zig"),
        .target = target,
        .optimize = optimize,
    });

    const luau_mod = luauModule(b, options);

    const luau_lib = b.addLibrary(.{
        .name = "luau",
        .root_module = luau_mod,
        .linkage = b.option(std.builtin.LinkMode, "linkage", "linkage for luau lib") orelse .static,
    });
    b.installArtifact(luau_lib);

    const luau_tc_mod = luauTranslateC(b, options);

    if (b.option(bool, "link_library", "link library to luau module") orelse true) {
        mod.linkLibrary(luau_lib);
    }
    mod.addImport("lua", luau_tc_mod);

    const exe = b.addExecutable(.{
        .name = "luau-example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "lua",
                    .module = mod,
                },
            },
        }),
    });

    const run_step = b.step("run-example", "");

    const run_exe = b.addRunArtifact(exe);
    run_step.dependOn(&run_exe.step);

    const test_step = b.step("test", "");

    const test_mod = b.addTest(.{ .root_module = mod });
    const run_test_mod = b.addRunArtifact(test_mod);
    test_step.dependOn(&run_test_mod.step);
}

const Options = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    luau_dep: *std.Build.Dependency,
};

pub fn luauModule(b: *std.Build, options: Options) *std.Build.Module {
    const luau_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .link_libcpp = true,
    });

    luau_mod.addIncludePath(options.luau_dep.path("Analysis/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Analysis/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Ast/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Ast/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Bytecode/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Bytecode/src"));
    luau_mod.addIncludePath(options.luau_dep.path("CodeGen/include"));
    luau_mod.addIncludePath(options.luau_dep.path("CodeGen/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Common/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Common/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Compiler/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Compiler/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Config/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Config/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Inliner/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Inliner/src"));
    luau_mod.addIncludePath(options.luau_dep.path("Require/include"));
    luau_mod.addIncludePath(options.luau_dep.path("Require/src"));
    luau_mod.addIncludePath(options.luau_dep.path("VM/include"));
    luau_mod.addIncludePath(options.luau_dep.path("VM/src"));

    const flags: []const []const u8 = &.{
        "-DLUA_USE_LONGJMP=1",
        "-DLUA_API=extern \"C\"",
        "-DLUACODE_API=extern \"C\"",
        "-DLUACODEGEN_API=extern \"C\"",
    };

    luau_mod.addCSourceFiles(.{
        .files = &.{
            "Analysis/src/Anyification.cpp",
            "Analysis/src/ApplyTypeFunction.cpp",
            "Analysis/src/AstJsonEncoder.cpp",
            "Analysis/src/AstQuery.cpp",
            "Analysis/src/AstUtils.cpp",
            "Analysis/src/Autocomplete.cpp",
            "Analysis/src/AutocompleteCore.cpp",
            "Analysis/src/BuiltinDefinitions.cpp",
            "Analysis/src/BuiltinTypeFunctions.cpp",
            "Analysis/src/Clone.cpp",
            "Analysis/src/Constraint.cpp",
            "Analysis/src/ConstraintGenerator.cpp",
            "Analysis/src/ConstraintGraph.cpp",
            "Analysis/src/ConstraintSolver.cpp",
            "Analysis/src/ControlFlowGraph.cpp",
            "Analysis/src/DataFlowGraph.cpp",
            "Analysis/src/DcrLogger.cpp",
            "Analysis/src/Def.cpp",
            "Analysis/src/DumpCFG.cpp",
            "Analysis/src/EmbeddedBuiltinDefinitions.cpp",
            "Analysis/src/Error.cpp",
            "Analysis/src/ExpectedTypeVisitor.cpp",
            "Analysis/src/FileResolver.cpp",
            "Analysis/src/FragmentAutocomplete.cpp",
            "Analysis/src/Frontend.cpp",
            "Analysis/src/Generalization.cpp",
            "Analysis/src/GlobalTypes.cpp",
            "Analysis/src/Instantiation.cpp",
            "Analysis/src/Instantiation2.cpp",
            "Analysis/src/IostreamHelpers.cpp",
            "Analysis/src/IterativeTypeFunctionTypeVisitor.cpp",
            "Analysis/src/IterativeTypeVisitor.cpp",
            "Analysis/src/JsonEmitter.cpp",
            "Analysis/src/LValue.cpp",
            "Analysis/src/Linter.cpp",
            "Analysis/src/Module.cpp",
            "Analysis/src/NativeStackGuard.cpp",
            "Analysis/src/NonStrictTypeChecker.cpp",
            "Analysis/src/Normalize.cpp",
            "Analysis/src/OverloadResolver.cpp",
            "Analysis/src/Quantify.cpp",
            "Analysis/src/RecursionCounter.cpp",
            "Analysis/src/Refinement.cpp",
            "Analysis/src/RequireTracer.cpp",
            "Analysis/src/Scope.cpp",
            "Analysis/src/Simplify.cpp",
            "Analysis/src/StructuralTypeEquality.cpp",
            "Analysis/src/Substitution.cpp",
            "Analysis/src/Subtyping.cpp",
            "Analysis/src/SubtypingUnifier.cpp",
            "Analysis/src/Symbol.cpp",
            "Analysis/src/TableLiteralInference.cpp",
            "Analysis/src/ToDot.cpp",
            "Analysis/src/ToString.cpp",
            "Analysis/src/TopoSortStatements.cpp",
            "Analysis/src/TxnLog.cpp",
            "Analysis/src/Type.cpp",
            "Analysis/src/TypeArena.cpp",
            "Analysis/src/TypeAttach.cpp",
            "Analysis/src/TypeChecker2.cpp",
            "Analysis/src/TypeFunction.cpp",
            "Analysis/src/TypeFunctionError.cpp",
            "Analysis/src/TypeFunctionReductionGuesser.cpp",
            "Analysis/src/TypeFunctionRuntime.cpp",
            "Analysis/src/TypeFunctionRuntimeBuilder.cpp",
            "Analysis/src/TypeIds.cpp",
            "Analysis/src/TypeInfer.cpp",
            "Analysis/src/TypeOrPack.cpp",
            "Analysis/src/TypePack.cpp",
            "Analysis/src/TypePath.cpp",
            "Analysis/src/TypeStateMap.cpp",
            "Analysis/src/TypeUtils.cpp",
            "Analysis/src/TypedAllocator.cpp",
            "Analysis/src/Unifiable.cpp",
            "Analysis/src/Unifier.cpp",
            "Analysis/src/Unifier2.cpp",
            "Analysis/src/UserDefinedTypeFunction.cpp",
            "Ast/src/Allocator.cpp",
            "Ast/src/Ast.cpp",
            "Ast/src/Confusables.cpp",
            "Ast/src/Cst.cpp",
            "Ast/src/Lexer.cpp",
            "Ast/src/Location.cpp",
            "Ast/src/Parser.cpp",
            "Ast/src/PrettyPrinter.cpp",
            "Bytecode/src/BytecodeBuilder.cpp",
            "Bytecode/src/BytecodeGraph.cpp",
            //"CLI/src/Analyze.cpp",
            //"CLI/src/AnalyzeRequirer.cpp",
            //"CLI/src/Ast.cpp",
            //"CLI/src/Bytecode.cpp",
            //"CLI/src/Compile.cpp",
            //"CLI/src/Counters.cpp",
            //"CLI/src/Coverage.cpp",
            //"CLI/src/FileUtils.cpp",
            //"CLI/src/Flags.cpp",
            //"CLI/src/Profiler.cpp",
            //"CLI/src/Reduce.cpp",
            //"CLI/src/Repl.cpp",
            //"CLI/src/ReplEntry.cpp",
            //"CLI/src/ReplRequirer.cpp",
            //"CLI/src/VfsNavigator.cpp",
            //"CLI/src/Web.cpp",
            "CodeGen/src/AssemblyBuilderA64.cpp",
            "CodeGen/src/AssemblyBuilderX64.cpp",
            "CodeGen/src/BytecodeAnalysis.cpp",
            "CodeGen/src/BytecodeSummary.cpp",
            "CodeGen/src/CodeAllocator.cpp",
            "CodeGen/src/CodeBlockUnwind.cpp",
            "CodeGen/src/CodeGen.cpp",
            "CodeGen/src/CodeGenA64.cpp",
            "CodeGen/src/CodeGenAssembly.cpp",
            "CodeGen/src/CodeGenContext.cpp",
            "CodeGen/src/CodeGenUtils.cpp",
            "CodeGen/src/CodeGenX64.cpp",
            "CodeGen/src/EmitBuiltinsX64.cpp",
            "CodeGen/src/EmitCommonX64.cpp",
            "CodeGen/src/EmitInstructionX64.cpp",
            "CodeGen/src/IrAnalysis.cpp",
            "CodeGen/src/IrBuilder.cpp",
            "CodeGen/src/IrCallWrapperX64.cpp",
            "CodeGen/src/IrDump.cpp",
            "CodeGen/src/IrLoweringA64.cpp",
            "CodeGen/src/IrLoweringX64.cpp",
            "CodeGen/src/IrRegAllocA64.cpp",
            "CodeGen/src/IrRegAllocX64.cpp",
            "CodeGen/src/IrTranslateBuiltins.cpp",
            "CodeGen/src/IrTranslation.cpp",
            "CodeGen/src/IrUtils.cpp",
            "CodeGen/src/IrValueLocationTracking.cpp",
            "CodeGen/src/NativeProtoExecData.cpp",
            "CodeGen/src/NativeState.cpp",
            "CodeGen/src/OptimizeConstProp.cpp",
            "CodeGen/src/OptimizeDeadStore.cpp",
            "CodeGen/src/OptimizeFinalX64.cpp",
            "CodeGen/src/SharedCodeAllocator.cpp",
            "CodeGen/src/UnwindBuilderDwarf2.cpp",
            "CodeGen/src/UnwindBuilderWin.cpp",
            "CodeGen/src/lcodegen.cpp",
            "Common/src/BytecodeWire.cpp",
            "Common/src/StringUtils.cpp",
            "Common/src/TimeTrace.cpp",
            "Compiler/src/BuiltinFolding.cpp",
            "Compiler/src/Builtins.cpp",
            "Compiler/src/Compiler.cpp",
            "Compiler/src/ConstantFolding.cpp",
            "Compiler/src/CostModel.cpp",
            "Compiler/src/TableShape.cpp",
            "Compiler/src/Types.cpp",
            "Compiler/src/ValueTracking.cpp",
            "Compiler/src/lcode.cpp",
            "Config/src/Config.cpp",
            "Config/src/LinterConfig.cpp",
            "Config/src/LuauConfig.cpp",
            "Inliner/src/JitInliner.cpp",
            "Inliner/src/luajitinliner.cpp",
            "Require/src/AliasCycleTracker.cpp",
            "Require/src/Navigation.cpp",
            "Require/src/PathUtilities.cpp",
            "Require/src/Require.cpp",
            "Require/src/RequireImpl.cpp",
            "Require/src/RequireNavigator.cpp",
            "VM/src/lapi.cpp",
            "VM/src/laux.cpp",
            "VM/src/lbaselib.cpp",
            "VM/src/lbitlib.cpp",
            "VM/src/lbuffer.cpp",
            "VM/src/lbuflib.cpp",
            "VM/src/lbuiltins.cpp",
            "VM/src/lclass.cpp",
            "VM/src/lclasslib.cpp",
            "VM/src/lcorolib.cpp",
            "VM/src/ldblib.cpp",
            "VM/src/ldebug.cpp",
            "VM/src/ldo.cpp",
            "VM/src/lfunc.cpp",
            "VM/src/lgc.cpp",
            "VM/src/lgcdebug.cpp",
            "VM/src/linit.cpp",
            "VM/src/lintlib.cpp",
            "VM/src/lmathlib.cpp",
            "VM/src/lmem.cpp",
            "VM/src/lnumprint.cpp",
            "VM/src/lobject.cpp",
            "VM/src/loslib.cpp",
            "VM/src/lperf.cpp",
            "VM/src/lstate.cpp",
            "VM/src/lstring.cpp",
            "VM/src/lstrlib.cpp",
            "VM/src/ltable.cpp",
            "VM/src/ltablib.cpp",
            "VM/src/ltm.cpp",
            "VM/src/ludata.cpp",
            "VM/src/lutf8lib.cpp",
            "VM/src/lveclib.cpp",
            "VM/src/lvmexecute.cpp",
            "VM/src/lvmload.cpp",
            "VM/src/lvmutils.cpp",
        },
        .flags = flags,
        .root = options.luau_dep.path("."),
    });

    return luau_mod;
}

pub fn luauTranslateC(b: *std.Build, options: Options) *std.Build.Module {
    const luau_c = b.addTranslateC(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = b.addWriteFile("include.h",
            \\#include "lua.h"
            \\#include "lualib.h"
            \\#include "luacode.h"
        ).getDirectory().path(b, "include.h"),
    });
    luau_c.addIncludePath(options.luau_dep.path("VM/include"));
    luau_c.addIncludePath(options.luau_dep.path("Compiler/include"));

    return luau_c.createModule();
}
