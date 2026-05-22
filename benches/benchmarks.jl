# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for HardwareResilience.jl.
# Measures guardian construction cost and monitor_kernel dispatch overhead.

using BenchmarkTools

include(joinpath(@__DIR__, "..", "src", "HardwareResilience.jl"))
using .HardwareResilience

println("=== HardwareResilience.jl Benchmarks ===")

# --- Construction benchmarks ---

println("\n-- KernelGuardian construction --")

# Small: construct a single guardian.
b_construct = @benchmark KernelGuardian("bench_g", :Healthy)
println("KernelGuardian construction: ", median(b_construct))

# --- monitor_kernel: successful op ---

println("\n-- monitor_kernel (success path) --")

g = KernelGuardian("bench_monitor", :Healthy)

# Small: trivial no-op.
b_noop = @benchmark monitor_kernel($g, () -> nothing)
println("monitor_kernel noop: ", median(b_noop))

# Medium: arithmetic op.
b_arith = @benchmark monitor_kernel($g, () -> sum(1:100))
println("monitor_kernel arithmetic (sum 1:100): ", median(b_arith))

# Large: allocating op.
b_alloc = @benchmark monitor_kernel($g, () -> rand(1000))
println("monitor_kernel rand(1000): ", median(b_alloc))

# --- monitor_kernel: error recovery path ---

println("\n-- monitor_kernel (error recovery path) --")

b_error = @benchmark monitor_kernel($g, () -> error("simulated fault"))
println("monitor_kernel error recovery: ", median(b_error))

# --- Status mutation ---

println("\n-- Status mutation --")

b_mutate = @benchmark $g.status = :Degraded
println("Status field mutation: ", median(b_mutate))
