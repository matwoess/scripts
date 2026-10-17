#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../general/resolve-host"
}

@test 'fails when no argument provided' {
	run "$script"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'shows help on -h and --help' {
	run "$script" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]

	run "$script" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'resolves localhost to 127.0.0.1' {
	run "$script" localhost
	[[ "$status" -eq 0 ]]
	[[ "$output" == '127.0.0.1' ]]
}

@test 'fails on unresolvable host' {
	run "$script" 'nonexistent-host-xyz-123'
	[[ "$status" -eq 1 ]]
	[[ "$output" == *'could not resolve "nonexistent-host-xyz-123" to an IP'* ]]
}
