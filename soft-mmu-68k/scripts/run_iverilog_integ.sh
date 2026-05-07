#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/.."

print_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

run_bench() {
  local name="$1"
  local out="$2"
  shift 2

  echo "==> RUN: ${name}"

  local compile_cmd=(iverilog -g2012 -I . -o "$out" "$@")
  print_cmd "${compile_cmd[@]}"
  if ! "${compile_cmd[@]}"; then
    echo "FAIL: ${name} (compile)"
    exit 1
  fi

  local sim_cmd=(vvp "$out")
  print_cmd "${sim_cmd[@]}"
  if ! "${sim_cmd[@]}"; then
    echo "FAIL: ${name} (simulation)"
    exit 1
  fi

  echo "PASS: ${name}"
  echo
}

run_bench "instr_shim_tb" "/tmp/instr_shim_tb" \
  tb/integ/instr_shim_tb.sv \
  rtl/core/flush_ctrl.v

run_bench "mmu_core_tb" "/tmp/mmu_core_tb" \
  tb/integ/mmu_core_tb.sv \
  rtl/core/mmu_top.v

run_bench "if_68k_shim_tb" "/tmp/if_68k_shim_tb" \
  tb/integ/if_68k_shim_tb.sv \
  rtl/bus/if_68k_shim.v

run_bench "if_axi_wb_bridge_tb" "/tmp/if_axi_wb_bridge_tb" \
  tb/integ/if_axi_wb_bridge_tb.sv \
  rtl/bus/if_axi_wb_bridge.v

echo "PASS: all Icarus integration benches"
