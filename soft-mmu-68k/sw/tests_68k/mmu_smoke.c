/*
 * First-pass TT/transparent smoke vectors for the 68k software scaffold.
 *
 * The current RTL policy in mmu_top is intentionally narrow:
 *   - A TT match bypasses translation and returns an identity-style PA.
 *   - A TT non-match falls back to the translated path.
 *   - CPU/special space never uses the TT bypass even if the region matches.
 *
 * This file keeps those expectations reviewable with explicit vectors and a
 * tiny local evaluator. A later harness can replace evaluate_case() with real
 * probe or access execution while keeping the vector table intact.
 */

#include <stdint.h>

enum smoke_space_kind {
    SMOKE_SPACE_DATA = 0,
    SMOKE_SPACE_PROGRAM = 1,
    SMOKE_SPACE_CPU = 2,
};

enum smoke_access_mode {
    SMOKE_MODE_USER = 0,
    SMOKE_MODE_SUPERVISOR = 1,
};

enum smoke_path_kind {
    SMOKE_PATH_TRANSLATED = 0,
    SMOKE_PATH_TRANSPARENT = 1,
};

struct ttr_image {
    uint8_t base_hi;
    uint8_t mask_hi;
    uint8_t enabled;
    uint8_t match_supervisor;
    uint8_t match_user;
    uint8_t match_program;
    uint8_t match_data;
};

struct smoke_case {
    uint32_t va;
    uint32_t translated_pa;
    struct ttr_image tt0;
    struct ttr_image tt1;
    uint8_t mode;
    uint8_t space;
    uint8_t expect_path;
    uint32_t expect_pa;
    const char *note;
};

struct smoke_result {
    uint8_t path;
    uint32_t pa;
};

static uint8_t ttr_matches(const struct ttr_image *ttr,
                           uint32_t va,
                           uint8_t is_user,
                           uint8_t is_program,
                           uint8_t is_data,
                           uint8_t is_cpu_space)
{
    uint8_t va_hi;
    uint8_t compare_mask;
    uint8_t privilege_ok;
    uint8_t space_ok;

    if (!ttr->enabled || is_cpu_space) {
        return 0u;
    }

    privilege_ok = (uint8_t)((is_user && ttr->match_user) ||
                             (!is_user && ttr->match_supervisor));
    space_ok = (uint8_t)((is_program && ttr->match_program) ||
                         (is_data && ttr->match_data));
    if (!privilege_ok || !space_ok) {
        return 0u;
    }

    va_hi = (uint8_t)(va >> 24);
    compare_mask = (uint8_t)~ttr->mask_hi;
    return (uint8_t)((va_hi & compare_mask) == (ttr->base_hi & compare_mask));
}

static struct smoke_result evaluate_case(const struct smoke_case *test_case)
{
    uint8_t is_user;
    uint8_t is_program;
    uint8_t is_data;
    uint8_t is_cpu_space;
    uint8_t transparent_match;
    struct smoke_result result;

    is_user = (uint8_t)(test_case->mode == SMOKE_MODE_USER);
    is_program = (uint8_t)(test_case->space == SMOKE_SPACE_PROGRAM);
    is_data = (uint8_t)(test_case->space == SMOKE_SPACE_DATA);
    is_cpu_space = (uint8_t)(test_case->space == SMOKE_SPACE_CPU);

    transparent_match = (uint8_t)(
        ttr_matches(&test_case->tt0, test_case->va, is_user, is_program, is_data, is_cpu_space) ||
        ttr_matches(&test_case->tt1, test_case->va, is_user, is_program, is_data, is_cpu_space));

    if (transparent_match) {
        result.path = SMOKE_PATH_TRANSPARENT;
        result.pa = test_case->va;
    } else {
        result.path = SMOKE_PATH_TRANSLATED;
        result.pa = test_case->translated_pa;
    }

    return result;
}

static const struct smoke_case k_smoke_cases[] = {
    {
        0x12003456u,
        0x00345000u,
        { 0x12u, 0x00u, 1u, 0u, 1u, 0u, 1u },
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        SMOKE_MODE_USER,
        SMOKE_SPACE_DATA,
        SMOKE_PATH_TRANSPARENT,
        0x12003456u,
        "user data access in TT0 region returns identity-style PA"
    },
    {
        0x13003456u,
        0x00A12000u,
        { 0x12u, 0x00u, 1u, 0u, 1u, 0u, 1u },
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        SMOKE_MODE_USER,
        SMOKE_SPACE_DATA,
        SMOKE_PATH_TRANSLATED,
        0x00A12000u,
        "non-matching region byte falls back to translated path"
    },
    {
        0x1200F000u,
        0x00000007u,
        { 0x12u, 0x00u, 1u, 1u, 1u, 1u, 1u },
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        SMOKE_MODE_SUPERVISOR,
        SMOKE_SPACE_CPU,
        SMOKE_PATH_TRANSLATED,
        0x00000007u,
        "CPU space explicitly avoids TT bypass even on byte match"
    },
    {
        0x34001000u,
        0x00111000u,
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        { 0x34u, 0x00u, 1u, 1u, 0u, 1u, 0u },
        SMOKE_MODE_SUPERVISOR,
        SMOKE_SPACE_PROGRAM,
        SMOKE_PATH_TRANSPARENT,
        0x34001000u,
        "TT1 can independently match supervisor program fetches"
    },
    {
        0x34002000u,
        0x00122000u,
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        { 0x34u, 0x00u, 1u, 1u, 0u, 1u, 0u },
        SMOKE_MODE_SUPERVISOR,
        SMOKE_SPACE_DATA,
        SMOKE_PATH_TRANSLATED,
        0x00122000u,
        "space-class mismatch keeps the access on the translated path"
    },
    {
        0xAB556677u,
        0x00666000u,
        { 0xA0u, 0x0Fu, 1u, 0u, 1u, 0u, 1u },
        { 0x00u, 0xFFu, 0u, 0u, 0u, 0u, 0u },
        SMOKE_MODE_USER,
        SMOKE_SPACE_DATA,
        SMOKE_PATH_TRANSPARENT,
        0xAB556677u,
        "mask bits allow a family of high-byte aliases to TT-match"
    },
};

int main(void)
{
    uint32_t i;
    int failures;

    failures = 0;
    for (i = 0; i < (uint32_t)(sizeof(k_smoke_cases) / sizeof(k_smoke_cases[0])); ++i) {
        struct smoke_result observed;
        const struct smoke_case *test_case;

        test_case = &k_smoke_cases[i];
        observed = evaluate_case(test_case);

        if ((observed.path != test_case->expect_path) ||
            (observed.pa != test_case->expect_pa)) {
            ++failures;
        }
    }

    return failures;
}
