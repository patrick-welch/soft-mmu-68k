#
# Minimal 68k software-test scaffold.
# This first pass is intentionally toolchain-neutral: callers must provide the
# tool variables explicitly, for example:
#   make -f sw/build/Makefile all \
#     CC_68K=m68k-elf-gcc \
#     CFLAGS_68K="-mc68020 -O2 -ffreestanding -Wall -Wextra"
#

TEST_DIR := sw/tests_68k
OUT_DIR := sw/build/out

export CC_68K
export CFLAGS_68K

TEST_SRCS := \
	$(TEST_DIR)/mmu_smoke.c \
	$(TEST_DIR)/mmu_perm.c

TEST_OBJS := $(patsubst $(TEST_DIR)/%.c,$(OUT_DIR)/%.o,$(TEST_SRCS))

.PHONY: all clean list-tests toolchain-check

all: $(TEST_OBJS)

list-tests:
	@printf '%s\n' $(TEST_SRCS)

toolchain-check:
	@test -n "$(CC_68K)" || { \
		echo "error: CC_68K is unset; provide a 68k C compiler, for example CC_68K=m68k-elf-gcc"; \
		exit 1; \
	}
	@test -n "$(CFLAGS_68K)" || { \
		echo "error: CFLAGS_68K is unset; provide target-specific flags, for example CFLAGS_68K='-mc68020 -O2 -ffreestanding -Wall -Wextra'"; \
		exit 1; \
	}

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/%.o: $(TEST_DIR)/%.c | $(OUT_DIR) toolchain-check
	$${CC_68K} $${CFLAGS_68K} -c $< -o $@

clean:
	rm -rf $(OUT_DIR)
