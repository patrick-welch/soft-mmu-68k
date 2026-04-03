/*
 * User/supervisor permission-policy vectors for the first-pass TT subset.
 *
 * Scope:
 *   - Translated accesses still obey the user/supervisor permission banks.
 *   - A TT match bypasses page-derived permission denial for a valid request.
 *   - CPU/special space never gains TT bypass in this first pass.
 *   - Malformed requests remain faults even when TT would otherwise match.
 */

#include <stdint.h>

enum perms_space_kind {
    PERMS_SPACE_DATA = 0,
    PERMS_SPACE_PROGRAM = 1,
    PERMS_SPACE_CPU = 2,
};

enum perms_request_kind {
    PERMS_REQ_READ = 0,
    PERMS_REQ_WRITE = 1,
    PERMS_REQ_FETCH = 2,
    PERMS_REQ_BAD = 3,
};

struct perms_case {
    uint8_t tt_match;
    uint8_t is_user;
    uint8_t space;
    uint8_t request;
    uint8_t u_perm;
    uint8_t s_perm;
    uint8_t expect_allow;
    uint8_t expect_fault;
    const char *note;
};

static uint8_t request_is_valid(uint8_t request)
{
    return (uint8_t)(request != PERMS_REQ_BAD);
}

static uint8_t request_is_tt_eligible(uint8_t request, uint8_t space)
{
    return (uint8_t)(request_is_valid(request) && (space != PERMS_SPACE_CPU));
}

static uint8_t permission_bit(uint8_t perm_bank, uint8_t request)
{
    if (request == PERMS_REQ_READ) {
        return (uint8_t)(perm_bank & 0x1u);
    }
    if (request == PERMS_REQ_WRITE) {
        return (uint8_t)((perm_bank >> 1) & 0x1u);
    }
    return (uint8_t)((perm_bank >> 2) & 0x1u);
}

static uint8_t evaluate_case(const struct perms_case *test_case, uint8_t *fault_out)
{
    uint8_t active_perm;
    uint8_t tt_bypass;
    uint8_t allowed;
    uint8_t fault;

    if (!request_is_valid(test_case->request)) {
        *fault_out = 0x10u;
        return 0u;
    }

    tt_bypass = (uint8_t)(test_case->tt_match &&
                          request_is_tt_eligible(test_case->request, test_case->space));
    active_perm = test_case->is_user ? test_case->u_perm : test_case->s_perm;
    allowed = permission_bit(active_perm, test_case->request);

    if (tt_bypass) {
        *fault_out = 0u;
        return 1u;
    }

    if (allowed) {
        *fault_out = 0u;
        return 1u;
    }

    if (test_case->request == PERMS_REQ_READ) {
        fault = 0x01u;
    } else if (test_case->request == PERMS_REQ_WRITE) {
        fault = 0x02u;
    } else {
        fault = 0x04u;
    }

    if (test_case->is_user && permission_bit(test_case->s_perm, test_case->request)) {
        fault = (uint8_t)(fault | 0x08u);
    }

    *fault_out = fault;
    return 0u;
}

static const struct perms_case k_perms_cases[] = {
    {
        0u, 1u, PERMS_SPACE_DATA, PERMS_REQ_READ,
        0x1u, 0x7u, 1u, 0x00u,
        "translated user read still works with user-read permission"
    },
    {
        0u, 1u, PERMS_SPACE_DATA, PERMS_REQ_WRITE,
        0x1u, 0x7u, 0u, 0x0Au,
        "translated user write faults and is privilege-related when supervisor could write"
    },
    {
        1u, 1u, PERMS_SPACE_DATA, PERMS_REQ_WRITE,
        0x1u, 0x7u, 1u, 0x00u,
        "TT match bypasses translated write denial for a valid user request"
    },
    {
        1u, 1u, PERMS_SPACE_CPU, PERMS_REQ_WRITE,
        0x1u, 0x7u, 0u, 0x0Au,
        "CPU-space access does not inherit TT bypass and still faults"
    },
    {
        0u, 1u, PERMS_SPACE_PROGRAM, PERMS_REQ_FETCH,
        0x3u, 0x7u, 0u, 0x0Cu,
        "translated user fetch faults with privilege-related execute denial"
    },
    {
        1u, 1u, PERMS_SPACE_PROGRAM, PERMS_REQ_FETCH,
        0x3u, 0x7u, 1u, 0x00u,
        "TT match lets the same user fetch through in first-pass policy"
    },
    {
        0u, 0u, PERMS_SPACE_DATA, PERMS_REQ_WRITE,
        0x1u, 0x3u, 1u, 0x00u,
        "supervisor write still follows supervisor bank on translated path"
    },
    {
        1u, 1u, PERMS_SPACE_DATA, PERMS_REQ_BAD,
        0x7u, 0x7u, 0u, 0x10u,
        "bad request encoding stays rejected even when TT would otherwise match"
    },
};

int main(void)
{
    uint32_t i;
    int failures;

    failures = 0;
    for (i = 0; i < (uint32_t)(sizeof(k_perms_cases) / sizeof(k_perms_cases[0])); ++i) {
        uint8_t observed_allow;
        uint8_t observed_fault;

        observed_allow = evaluate_case(&k_perms_cases[i], &observed_fault);
        if ((observed_allow != k_perms_cases[i].expect_allow) ||
            (observed_fault != k_perms_cases[i].expect_fault)) {
            ++failures;
        }
    }

    return failures;
}
