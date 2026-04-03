/*
 * TLB maintenance / probe-oriented scaffold for the first-pass TT subset.
 *
 * This file models the software-visible intent of flush and probe flows:
 *   - targeted flushes remove translated entries for the matching VA+FC only
 *   - whole-TLB flush clears translated state broadly
 *   - TT matches probe as usable results with identity-style PA
 *   - TT matches are not themselves "TLB hits", so translated invalidation does
 *     not remove transparent behavior
 */

#include <stdint.h>

enum tlb_step_kind {
    TLB_STEP_PROBE = 0,
    TLB_STEP_FLUSH_MATCH = 1,
    TLB_STEP_FLUSH_ALL = 2,
};

enum tlb_probe_expect_kind {
    TLB_EXPECT_MISS = 0,
    TLB_EXPECT_TRANSLATED = 1,
    TLB_EXPECT_TRANSPARENT = 2,
};

struct tlb_case {
    uint8_t step;
    uint32_t va;
    uint8_t fc;
    uint8_t expect_kind;
    uint32_t expect_pa;
    const char *note;
};

struct tlb_state {
    uint8_t translated_user_data_valid;
    uint8_t translated_super_program_valid;
};

struct probe_result {
    uint8_t kind;
    uint32_t pa;
};

static uint8_t tt_match_for_probe(uint32_t va, uint8_t fc)
{
    uint8_t va_hi;

    va_hi = (uint8_t)(va >> 24);
    if (fc == 0x1u) {
        return (uint8_t)(va_hi == 0x12u);
    }
    if (fc == 0x6u) {
        return (uint8_t)(va_hi == 0x34u);
    }
    return 0u;
}

static struct probe_result run_probe(const struct tlb_state *state, uint32_t va, uint8_t fc)
{
    struct probe_result result;

    result.kind = TLB_EXPECT_MISS;
    result.pa = 0u;

    if (tt_match_for_probe(va, fc)) {
        result.kind = TLB_EXPECT_TRANSPARENT;
        result.pa = va;
        return result;
    }

    if (state->translated_user_data_valid &&
        (fc == 0x1u) &&
        (va == 0x90001000u)) {
        result.kind = TLB_EXPECT_TRANSLATED;
        result.pa = 0x00101000u;
        return result;
    }

    if (state->translated_super_program_valid &&
        (fc == 0x6u) &&
        (va == 0x90002000u)) {
        result.kind = TLB_EXPECT_TRANSLATED;
        result.pa = 0x00202000u;
        return result;
    }

    return result;
}

static void apply_flush_match(struct tlb_state *state, uint32_t va, uint8_t fc)
{
    if ((fc == 0x1u) && (va == 0x90001000u)) {
        state->translated_user_data_valid = 0u;
    }
    if ((fc == 0x6u) && (va == 0x90002000u)) {
        state->translated_super_program_valid = 0u;
    }
}

static void apply_flush_all(struct tlb_state *state)
{
    state->translated_user_data_valid = 0u;
    state->translated_super_program_valid = 0u;
}

static const struct tlb_case k_tlb_cases[] = {
    {
        TLB_STEP_PROBE, 0x90001000u, 0x1u, TLB_EXPECT_TRANSLATED, 0x00101000u,
        "baseline translated user-data probe hits the simulated TLB"
    },
    {
        TLB_STEP_FLUSH_MATCH, 0x90001000u, 0x1u, TLB_EXPECT_MISS, 0u,
        "targeted flush removes only the matching translated entry"
    },
    {
        TLB_STEP_PROBE, 0x90001000u, 0x1u, TLB_EXPECT_MISS, 0u,
        "post-flush probe for that VA+FC becomes a translated miss"
    },
    {
        TLB_STEP_PROBE, 0x90002000u, 0x6u, TLB_EXPECT_TRANSLATED, 0x00202000u,
        "unrelated supervisor-program translation survives the targeted flush"
    },
    {
        TLB_STEP_PROBE, 0x12001234u, 0x1u, TLB_EXPECT_TRANSPARENT, 0x12001234u,
        "TT-qualified probe reports identity-style PA instead of translated data"
    },
    {
        TLB_STEP_FLUSH_MATCH, 0x12001234u, 0x1u, TLB_EXPECT_MISS, 0u,
        "targeted translated flush does not erase transparent qualification itself"
    },
    {
        TLB_STEP_PROBE, 0x12001234u, 0x1u, TLB_EXPECT_TRANSPARENT, 0x12001234u,
        "transparent probe result remains after translated targeted flush"
    },
    {
        TLB_STEP_FLUSH_ALL, 0u, 0u, TLB_EXPECT_MISS, 0u,
        "whole-TLB flush clears the remaining translated entries"
    },
    {
        TLB_STEP_PROBE, 0x90002000u, 0x6u, TLB_EXPECT_MISS, 0u,
        "whole-TLB flush removes the remaining translated supervisor-program entry"
    },
    {
        TLB_STEP_PROBE, 0x12001234u, 0x7u, TLB_EXPECT_MISS, 0u,
        "CPU-space probe does not use TT bypass even when the address byte matches"
    },
};

int main(void)
{
    uint32_t i;
    int failures;
    struct tlb_state state;

    failures = 0;
    state.translated_user_data_valid = 1u;
    state.translated_super_program_valid = 1u;

    for (i = 0; i < (uint32_t)(sizeof(k_tlb_cases) / sizeof(k_tlb_cases[0])); ++i) {
        const struct tlb_case *test_case;

        test_case = &k_tlb_cases[i];
        if (test_case->step == TLB_STEP_PROBE) {
            struct probe_result observed;

            observed = run_probe(&state, test_case->va, test_case->fc);
            if ((observed.kind != test_case->expect_kind) ||
                (observed.pa != test_case->expect_pa)) {
                ++failures;
            }
        } else if (test_case->step == TLB_STEP_FLUSH_MATCH) {
            apply_flush_match(&state, test_case->va, test_case->fc);
        } else {
            apply_flush_all(&state);
        }
    }

    return failures;
}
