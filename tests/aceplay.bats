#!/usr/bin/env bats

setup() {
	script="$BATS_TEST_DIRNAME/../media/aceplay"
	mock_bin="$BATS_TEST_TMPDIR/bin"
	vlc_log="$BATS_TEST_TMPDIR/vlc_args"

	mkdir -p "$mock_bin"
	cat <<'EOF' > "$mock_bin/vlc"
#!/usr/bin/env bash
printf '%s\n' "$*" > "$VLC_LOG"
EOF
	chmod +x "$mock_bin/vlc"

	export VLC_LOG="$vlc_log"
	export PATH="$mock_bin:$PATH"
}

@test 'fails when no stream id is provided' {
	run "$script"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'shows help message on -h and --help' {
	run "$script" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]

	run "$script" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Usage:'* ]]
}

@test 'fails when stream id is empty' {
	run "$script" 'acestream://'

	[[ "$status" -eq 1 ]]
	[[ "$output" == *'error: stream ID is required'* ]]
}

@test 'connects to default host and launches vlc with stream url' {
	run "$script" '4a6b8c'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Connecting to Ace Stream gateway at 192.168.1.1:6878'* ]]
	[[ "$output" == *'Stream ID: 4a6b8c'* ]]
	[[ "$output" == *'Launching VLC: http://192.168.1.1:6878/ace/getstream?id=4a6b8c'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=4a6b8c' ]]
}

@test 'strips acestream:// prefix and trailing slash' {
	run "$script" 'acestream://xyz123/'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Stream ID: xyz123'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=xyz123' ]]
}

@test 'respects ACE_HOST and ACE_PORT overrides and passes vlc flags' {
	run env ACE_HOST='10.0.0.5' ACE_PORT='8000' "$script" 'abc' --fullscreen

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Connecting to Ace Stream gateway at 10.0.0.5:8000'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://10.0.0.5:8000/ace/getstream?id=abc --fullscreen' ]]
}

@test 'fails when vlc is missing' {
	local no_vlc_bin="$BATS_TEST_TMPDIR/no_vlc"
	mkdir -p "$no_vlc_bin"
	ln -s "$(command -v bash)" "$no_vlc_bin/bash"

	run env PATH="$no_vlc_bin" "$script" 'abc'

	[[ "$status" -eq 1 ]]
	[[ "$output" == *'vlc is not installed or not in PATH'* ]]
}
