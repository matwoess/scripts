#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../general/resolve-mac"
}

@test 'shows usage when no argument provided' {
	run "$script"
	[[ "$status" -eq 0 ]]
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

@test 'fails on unresolvable IP' {
	run "$script" '192.0.2.254'
	[[ "$status" -eq 1 ]]
	[[ "$output" == *'could not resolve MAC address for "192.0.2.254"'* ]]
}

@test 'resolves MAC when found via ip neigh' {
	mock_bin="$(mktemp -d)"
	cat <<'EOF' > "$mock_bin/ip"
#!/usr/bin/env bash
if [[ "$*" == *"neigh show 192.168.1.99"* ]]; then
	echo "192.168.1.99 dev eth0 lladdr aa:bb:cc:dd:ee:ff REACHABLE"
fi
EOF
	chmod +x "$mock_bin/ip"

	PATH="$mock_bin:$PATH" run "$script" '192.168.1.99'

	rm -rf "$mock_bin"
	[[ "$status" -eq 0 ]]
	[[ "$output" == 'aa:bb:cc:dd:ee:ff' ]]
}
