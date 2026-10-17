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

	cat <<'EOF' > "$mock_bin/chromecast-scan"
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$mock_bin/chromecast-scan"

	export VLC_LOG="$vlc_log"
	export PATH="$mock_bin:$BATS_TEST_DIRNAME/../general:$BATS_TEST_DIRNAME/../media:$PATH"
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

@test 'scans and lists chromecasts, choosing the first reachable device' {
	cat <<'EOF' > "$mock_bin/chromecast-scan"
#!/usr/bin/env bash
printf 'Living Room\t192.168.1.50\tGoogle TV\n'
printf 'Bedroom\t192.168.1.51\tChromecast Ultra\n'
EOF
	chmod +x "$mock_bin/chromecast-scan"

	cat <<'EOF' > "$mock_bin/ping"
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$mock_bin/ping"

	run "$script" '4a6b8c'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Found 2 Chromecast device(s):'* ]]
	[[ "$output" == *'- Living Room (192.168.1.50, Google TV)'* ]]
	[[ "$output" == *'- Bedroom (192.168.1.51, Chromecast Ultra)'* ]]
	[[ "$output" == *'Selected "Living Room" (192.168.1.50), casting via VLC'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=4a6b8c --sout-chromecast-ip=192.168.1.50' ]]
}

@test 'falls back to local VLC when no chromecasts found' {
	run "$script" '4a6b8c'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'No Chromecast devices found, starting VLC locally'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=4a6b8c' ]]
}

@test 'respects CAST_DEVICE and uses resolve-host' {
	cat <<'EOF' > "$mock_bin/ping"
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$mock_bin/ping"

	run env CAST_DEVICE='localhost' "$script" 'abc'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Resolved localhost to 127.0.0.1 (reachable), casting via VLC'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=abc --sout-chromecast-ip=127.0.0.1' ]]
}

@test 'disables casting when CAST_DEVICE=off' {
	run env CAST_DEVICE='off' "$script" 'abc'

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Casting disabled by CAST_DEVICE=off'* ]]

	run cat "$vlc_log"
	[[ "$output" == 'http://192.168.1.1:6878/ace/getstream?id=abc' ]]
}

@test 'fails when vlc is missing' {
	local no_vlc_bin="$BATS_TEST_TMPDIR/no_vlc"
	mkdir -p "$no_vlc_bin"
	ln -s "$(command -v bash)" "$no_vlc_bin/bash"

	run env PATH="$no_vlc_bin" "$script" 'abc'

	[[ "$status" -eq 1 ]]
	[[ "$output" == *'vlc is not installed or not in PATH'* ]]
}
