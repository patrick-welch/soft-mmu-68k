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

run_bench "mmu_regs_tb" "/tmp/mmu_regs_tb" \
  tb/unit/mmu_regs_tb.sv \
  rtl/core/mmu_regs.v

run_bench "descriptor_pack_tb" "/tmp/descriptor_pack_tb" \
  tb/unit/descriptor_pack_tb.sv \
  rtl/core/descriptor_pack.v

run_bench "perm_check_tb" "/tmp/perm_check_tb" \
  tb/unit/perm_check_tb.sv \
  rtl/core/perm_check.v \
  rtl/core/mmu_decode.v

run_bench "tlb_dm_tb" "/tmp/tlb_dm_tb" \
  tb/unit/tlb_dm_tb.sv \
  rtl/core/tlb_compare.v \
  rtl/core/tlb_dm.v

run_bench "pt_walker_tb" "/tmp/pt_walker_tb" \
  tb/unit/pt_walker_tb.sv \
  rtl/core/pt_walker.v

echo "PASS: all Icarus unit benches"
