# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for HardwareResilience.jl.

using Test

include(joinpath(@__DIR__, "..", "src", "HardwareResilience.jl"))
using .HardwareResilience

@testset "Property-Based Tests" begin

    @testset "KernelGuardian: name and status are always readable after construction" begin
        statuses = [:Healthy, :Degraded, :Failed, :Recovering, :Unknown]
        for _ in 1:50
            name = "guard_$(rand(1:10000))"
            status = rand(statuses)
            g = KernelGuardian(name, status)
            @test g.name == name
            @test g.status === status
        end
    end

    @testset "KernelGuardian: mutable fields accept any symbol status" begin
        g = KernelGuardian("prop_test", :Healthy)
        statuses = [:Healthy, :Degraded, :Failed, :Recovering, :Unknown]
        for _ in 1:50
            new_status = rand(statuses)
            g.status = new_status
            @test g.status === new_status
        end
    end

    @testset "monitor_kernel: non-throwing op always returns op result" begin
        g = KernelGuardian("prop_monitor", :Healthy)
        for _ in 1:50
            val = rand(Int)
            result = monitor_kernel(g, () -> val)
            @test result == val
        end
    end

    @testset "monitor_kernel: throwing op always returns nothing" begin
        g = KernelGuardian("prop_error", :Healthy)
        error_fns = [
            () -> error("random error"),
            () -> throw(DomainError(-1, "bad")),
            () -> [1][99],
        ]
        for _ in 1:50
            fn = rand(error_fns)
            result = monitor_kernel(g, fn)
            @test result === nothing
        end
    end

    @testset "monitor_kernel: identity invariant — op returning nothing gives nothing" begin
        g = KernelGuardian("prop_nothing", :Healthy)
        for _ in 1:50
            result = monitor_kernel(g, () -> nothing)
            @test result === nothing
        end
    end

    @testset "KernelGuardian: ismutable invariant always holds" begin
        for _ in 1:50
            g = KernelGuardian("x_$(rand(1:9999))", :Healthy)
            @test ismutable(g)
        end
    end

    @testset "monitor_kernel: string results are preserved exactly" begin
        g = KernelGuardian("prop_str", :Healthy)
        for _ in 1:50
            s = "result_$(rand(1:99999))"
            result = monitor_kernel(g, () -> s)
            @test result == s
        end
    end

end
