const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = std.zig.CrossTarget{
        .abi = .none,
        .os_tag = .freestanding,
        .cpu_arch = .aarch64,
    };
    const optimize = b.standardOptimizeOption(.{});

    const elf = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    elf.setLinkerScript(.{ .path = "linker.ld" });
    b.installArtifact(elf);

    const bin = b.addObjCopy(elf.getEmittedBin(), .{ .format = .bin });
    const bin_step = b.addInstallBinFile(bin.getOutput(), "kernel.img");
    b.default_step.dependOn(&bin_step.step);

    const qemu = b.addSystemCommand(&[_][]const u8{
        "qemu-system-aarch64",
        "-M", "raspi3b",
        "-cpu", "cortex-a53",
        "-serial", "null",
        "-serial", "stdio",
        "-display", "none",
        "-kernel", b.getInstallPath(bin_step.dir, bin_step.dest_rel_path)
    });
    qemu.step.dependOn(&bin_step.step);
    const qemu_step = b.step("qemu", "Run kernel in QEMU.");
    qemu_step.dependOn(&qemu.step);
}
