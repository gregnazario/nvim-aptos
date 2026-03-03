NVIM ?= nvim

.PHONY: test test-util test-init test-cli

test: test-util test-init test-cli

test-util:
	$(NVIM) --headless -u tests/minimal_init.lua -c "luafile tests/test_util.lua" -c "qa!"

test-init:
	$(NVIM) --headless -u tests/minimal_init.lua -c "luafile tests/test_init.lua" -c "qa!"

test-cli:
	$(NVIM) --headless -u tests/minimal_init.lua -c "luafile tests/test_cli.lua" -c "qa!"
