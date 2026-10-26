#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../android/androidtv-turn-on"
}

@test 'shows help on -h and --help' {
	run "$script" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]

	run "$script" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'fails on unresolvable target' {
	run "$script" 'nonexistent-tv.local'
	[[ "$status" -eq 1 ]]
	[[ "$output" == *'could not resolve "nonexistent-tv.local"'* ]]
}

@test 'resolves via chromecast-scan and sends adb keyevent 224' {
	mock_bin="$(mktemp -d)"
	cat <<'EOF' > "$mock_bin/chromecast-scan"
#!/usr/bin/env bash
printf 'Dunja\t192.168.1.123\tKAGIS Android TV\n'
EOF
	cat <<'EOF' > "$mock_bin/adb"
#!/usr/bin/env bash
echo "adb $@"
EOF
	chmod +x "$mock_bin/chromecast-scan" "$mock_bin/adb"

	PATH="$mock_bin:$PATH" run "$script" 'Dunja.local'

	rm -rf "$mock_bin"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Scanning for "Dunja" via chromecast-scan...'* ]]
	[[ "$output" == *'adb -s 192.168.1.123:5555 shell input keyevent 224'* ]]
	[[ "$output" == *'Successfully sent wakeup command to Dunja.local'* ]]
}

@test 'accepts IP directly and sends adb keyevent 224' {
	mock_bin="$(mktemp -d)"
	cat <<'EOF' > "$mock_bin/adb"
#!/usr/bin/env bash
echo "adb $@"
EOF
	chmod +x "$mock_bin/adb"

	PATH="$mock_bin:$PATH" run "$script" '192.168.1.200'

	rm -rf "$mock_bin"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Connecting to 192.168.1.200 (192.168.1.200:5555)...'* ]]
	[[ "$output" == *'adb -s 192.168.1.200:5555 shell input keyevent 224'* ]]
}
