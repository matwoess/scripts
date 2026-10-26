#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../android/tv-vlc"
}

@test 'shows help on -h and --help' {
	run "$script" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]

	run "$script" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'fails with no arguments' {
	run "$script"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'prepends file:// for local paths and escapes spaces' {
	mock_bin="$(mktemp -d)"
	cat <<'EOF' > "$mock_bin/adb"
#!/usr/bin/env bash
echo "adb $@"
EOF
	chmod +x "$mock_bin/adb"

	PATH="$mock_bin:$PATH" run "$script" '/storage/12AB-34CD/My Movie.mkv'

	rm -rf "$mock_bin"
	[[ "$status" -eq 0 ]]
	[[ "$output" == 'adb shell am start -a android.intent.action.VIEW -p org.videolan.vlc -t video/* -d file:///storage/12AB-34CD/My\ Movie.mkv' ]]
}

@test 'passes network URIs through unchanged' {
	mock_bin="$(mktemp -d)"
	cat <<'EOF' > "$mock_bin/adb"
#!/usr/bin/env bash
echo "adb $@"
EOF
	chmod +x "$mock_bin/adb"

	PATH="$mock_bin:$PATH" run "$script" 'smb://192.168.1.100/share/video.mkv'

	rm -rf "$mock_bin"
	[[ "$status" -eq 0 ]]
	[[ "$output" == 'adb shell am start -a android.intent.action.VIEW -p org.videolan.vlc -t video/* -d smb://192.168.1.100/share/video.mkv' ]]
}
