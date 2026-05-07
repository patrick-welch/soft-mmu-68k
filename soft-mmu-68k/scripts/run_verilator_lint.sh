#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/.."

print_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

run_lint() {
  local name="$1"
  shift

  echo "==> LINT: ${name}"

  local lint_cmd=(verilator --lint-only -Wall -Wno-fatal -I. "$@")
  print_cmd "${lint_cmd[@]}"
  if ! "${lint_cmd[@]}"; then
    echo "FAIL: ${name}"
    exit 1
  fi

  echo "PASS: ${name}"
  echo
}

echo "Note: -Wno-fatal keeps current accepted warnings visible while preserving failure on errors."
echo "Accepted warnings in this flow are pre-existing Verilator warnings from delay-based benches and the Basys 3 smoke top."
echo

run_lint "core RTL: descriptor_pack" \
  rtl/core/descriptor_pack.v

run_lint "core RTL: mmu_top structural closure" \
  rtl/core/mmu_regs.v \
  rtl/core/mmu_decode.v \
  rtl/core/perm_check.v \
  rtl/core/tlb_compare.v \
  rtl/core/tlb_dm.v \
  rtl/core/pt_walker.v \
  rtl/core/flush_ctrl.v \
  rtl/core/mmu_top.v

run_lint "bus shim: if_68k_shim" \
  rtl/bus/if_68k_shim.v

run_lint "bus shim: if_axi_wb_bridge" \
  rtl/bus/if_axi_wb_bridge.v

run_lint "Basys 3 top: top_mmu_demo" \
  rtl/core/mmu_regs.v \
  rtl/core/mmu_decode.v \
  rtl/core/perm_check.v \
  rtl/core/tlb_compare.v \
  rtl/core/tlb_dm.v \
  rtl/core/pt_walker.v \
  rtl/core/flush_ctrl.v \
  rtl/core/mmu_top.v \
  fpga/basys3/tops/top_mmu_demo.v

run_lint "bench: mmu_regs_tb" \
  tb/unit/mmu_regs_tb.sv \
  rtl/core/mmu_regs.v

run_lint "bench: descriptor_pack_tb" \
  tb/unit/descriptor_pack_tb.sv \
  rtl/core/descriptor_pack.v

run_lint "bench: perm_check_tb" \
  tb/unit/perm_check_tb.sv \
  rtl/core/perm_check.v \
  rtl/core/mmu_decode.v

run_lint "bench: tlb_dm_tb" \
  tb/unit/tlb_dm_tb.sv \
  rtl/core/tlb_compare.v \
  rtl/core/tlb_dm.v

run_lint "bench: pt_walker_tb" \
  tb/unit/pt_walker_tb.sv \
  rtl/core/pt_walker.v

run_lint "bench: instr_shim_tb" \
  tb/integ/instr_shim_tb.sv \
  rtl/core/flush_ctrl.v

run_lint "bench: mmu_core_tb" \
  tb/integ/mmu_core_tb.sv \
  rtl/core/mmu_top.v

run_lint "bench: if_68k_shim_tb" \
  tb/integ/if_68k_shim_tb.sv \
  rtl/bus/if_68k_shim.v

run_lint "bench: if_axi_wb_bridge_tb" \
  tb/integ/if_axi_wb_bridge_tb.sv \
  rtl/bus/if_axi_wb_bridge.v

echo "PASS: all Verilator lint targets"
