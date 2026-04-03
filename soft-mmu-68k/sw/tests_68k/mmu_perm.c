/*
 * Minimal MMU permission-fault scaffold for 68k software-side validation.
 *
 * Intent:
 *   - Exercise the policy side of translation rather than address reachability.
 *   - Provide fixed vectors that can later be paired with page-descriptor
 *     attributes such as supervisor-only and write-protect bits.
 *   - Align with the current RTL direction where the page-table walker forwards
 *     attributes and a later stage is expected to turn them into permission
 *     faults for loads, stores, and instruction fetches.
 */

#include <stdint.h>

enum perm_access_kind {
    PERM_ACCESS_READ = 0,
    PERM_ACCESS_WRITE = 1,
    PERM_ACCESS_FETCH = 2,
};

enum perm_expected_result {
    PERM_EXPECT_ALLOW = 0,
    PERM_EXPECT_FAULT = 1,
};

struct mmu_perm_case {
    uint32_t va;
    uint8_t access;
    uint8_t supervisor;
    uint8_t write_protect;
    uint8_t supervisor_only;
    uint8_t expect;
    const char *note;
};

static const struct mmu_perm_case k_mmu_perm_cases[] = {
    /* User read from a normal user page should succeed. */
    { 0x00003000u, PERM_ACCESS_READ,  0u, 0u, 0u, PERM_EXPECT_ALLOW, "user read allowed" },
    /* User write to a write-protected page should fault once permission checks exist. */
    { 0x00004000u, PERM_ACCESS_WRITE, 0u, 1u, 0u, PERM_EXPECT_FAULT, "user write hits write-protect" },
    /* User access to a supervisor page should fault. */
    { 0x00005000u, PERM_ACCESS_READ,  0u, 0u, 1u, PERM_EXPECT_FAULT, "user read hits supervisor-only page" },
    /* Supervisor write to a supervisor page is expected to pass in the simple model. */
    { 0x00006000u, PERM_ACCESS_WRITE, 1u, 0u, 1u, PERM_EXPECT_ALLOW, "supervisor write allowed" },
};

static int evaluate_case(const struct mmu_perm_case *test_case)
{
    if (test_case->supervisor_only && !test_case->supervisor) {
        return PERM_EXPECT_FAULT;
    }

    if (test_case->write_protect && (test_case->access == PERM_ACCESS_WRITE)) {
        return PERM_EXPECT_FAULT;
    }

    return PERM_EXPECT_ALLOW;
}

int main(void)
{
    uint32_t i;
    int failures = 0;

    for (i = 0; i < (uint32_t)(sizeof(k_mmu_perm_cases) / sizeof(k_mmu_perm_cases[0])); ++i) {
        const struct mmu_perm_case *test_case = &k_mmu_perm_cases[i];
        int observed = evaluate_case(test_case);

        if (observed != (int)test_case->expect) {
            ++failures;
        }
    }

    /*
     * Later integration can map each case to real descriptor bits and verify
     * that the MMU exception path reports the same allow/fault result.
     */
    return failures;
}
