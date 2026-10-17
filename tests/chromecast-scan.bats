#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../media/chromecast-scan"
}

@test 'shows help on -h and --help' {
	run "$script" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'usage: chromecast-scan'* ]]

	run "$script" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'usage: chromecast-scan'* ]]
}

@test 'fails when -t missing argument' {
	run "$script" -t
	[[ "$status" -eq 2 ]]
	[[ "$output" == *'expected one argument'* ]]
}

@test 'fails on unexpected option' {
	run "$script" --unknown
	[[ "$status" -eq 2 ]]
	[[ "$output" == *'unrecognized arguments'* ]]
}
