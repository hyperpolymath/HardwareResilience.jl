# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for HardwareResilience.jl
# Tests the full lifecycle: guardian creation → monitoring → failure recovery → state change.

using Test

include(joinpath(@__DIR__, "..", "src", "HardwareResilience.jl"))
using .HardwareResilience

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: healthy operation" begin
        # Create a guardian, run a successful operation, verify result flows through.
        g = KernelGuardian("e2e_healthy", :Healthy)
        payload = monitor_kernel(g, () -> [1, 2, 3, 4, 5])
        @test payload == [1, 2, 3, 4, 5]
        @test g.status === :Healthy  # status unchanged on success
    end

    @testset "Full pipeline: degraded operation" begin
        # Guardian in Degraded state should still allow monitored operations.
        g = KernelGuardian("e2e_degraded", :Degraded)
        result = monitor_kernel(g, () -> "degraded but operational")
        @test result == "degraded but operational"
    end

    @testset "Full pipeline: error handling and recovery" begin
        # Simulate a hardware failure, verify nil return, then recover via mutation.
        g = KernelGuardian("e2e_recovery", :Healthy)
        result = monitor_kernel(g, () -> error("simulated hardware fault"))
        @test result === nothing
        # Recover: mark as recovering.
        g.status = :Recovering
        @test g.status === :Recovering
        # After recovery, successful op works again.
        result2 = monitor_kernel(g, () -> "back online")
        @test result2 == "back online"
        g.status = :Healthy
        @test g.status === :Healthy
    end

    @testset "Full pipeline: sequential operations" begin
        # Chain multiple monitored ops through the same guardian.
        g = KernelGuardian("e2e_sequential", :Healthy)
        results = []
        for i in 1:5
            r = monitor_kernel(g, () -> i * 10)
            push!(results, r)
        end
        @test results == [10, 20, 30, 40, 50]
    end

    @testset "Error handling: DomainError in pipeline" begin
        g = KernelGuardian("e2e_domain", :Healthy)
        result = monitor_kernel(g, () -> sqrt(-1.0))
        # sqrt of negative throws DomainError
        @test result === nothing
    end

    @testset "Error handling: BoundsError in pipeline" begin
        g = KernelGuardian("e2e_bounds", :Healthy)
        result = monitor_kernel(g, () -> [1, 2, 3][99])
        @test result === nothing
    end

    @testset "Round-trip consistency: name and status" begin
        # Create, rename via mutation, verify all fields remain consistent.
        g = KernelGuardian("original_name", :Unknown)
        @test g.name == "original_name"
        @test g.status === :Unknown

        g.name = "updated_name"
        g.status = :Healthy
        @test g.name == "updated_name"
        @test g.status === :Healthy

        # Run op and verify guardian identity is preserved.
        result = monitor_kernel(g, () -> g.name)
        @test result == "updated_name"
    end

    @testset "Round-trip consistency: multiple guardians independent" begin
        # Two guardians do not share state.
        g1 = KernelGuardian("g1", :Healthy)
        g2 = KernelGuardian("g2", :Degraded)
        g1.status = :Failed
        @test g1.status === :Failed
        @test g2.status === :Degraded  # g2 unaffected
    end

end
