#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# or if an undefined variable is referenced.
set -euo pipefail

# Define source directories relative to this script's location
script_dir=${BASH_SOURCE[0]%/*}
if [[ $script_dir == "${BASH_SOURCE[0]}" ]]; then
	script_dir='.'
fi
repo_dir=$(cd -- "$script_dir" && pwd)
src_bin_dir="$repo_dir/bin"
src_gamestart_dir="$repo_dir/gamesstart"
src_scripts_dir="$repo_dir/scripts"

target_bin_dir="$HOME/bin"

# Color codes
color_gray='\e[90m'
color_green='\e[32m'
color_red='\e[31m'
color_reset='\e[0m'

log_noop() {
	local msg=$1
	printf '%b[NO-OP]   %s%b\n' "$color_gray" "$msg" "$color_reset" >&2
}

log_new() {
	local msg=$1
	printf '%b[NEW]     %s%b\n' "$color_green" "$msg" "$color_reset" >&2
}

log_removed() {
	local msg=$1
	printf '%b[REMOVED] %s%b\n' "$color_red" "$msg" "$color_reset" >&2
}

log_error() {
	local msg=$1
	printf '%b[ERROR]   %s%b\n' "$color_red" "$msg" "$color_reset" >&2
}

# 1. Ensure target bin directory exists and is a directory
if [[ -L $target_bin_dir ]]; then
	current_target=$(readlink "$target_bin_dir")
	rm "$target_bin_dir"
	log_removed "$target_bin_dir (symlink pointing to $current_target)"
fi

if [[ -e $target_bin_dir && ! -d $target_bin_dir ]]; then
	log_error "$target_bin_dir exists but is not a directory."
	exit 1
fi

if [[ ! -d $target_bin_dir ]]; then
	mkdir -p "$target_bin_dir"
	log_new "$target_bin_dir (directory created)"
fi

# 2. Collect expected symlinks
declare -A expected_links

# Link the gamestart directory (source is gamesstart)
if [[ -d $src_gamestart_dir ]]; then
	expected_links["$target_bin_dir/gamestart"]=$src_gamestart_dir
else
	log_error "Source directory gamesstart not found at $src_gamestart_dir"
fi

# Link the scripts directory
if [[ -d $src_scripts_dir ]]; then
	expected_links["$target_bin_dir/scripts"]=$src_scripts_dir
else
	log_error "Source directory scripts not found at $src_scripts_dir"
fi

# Link all individual files in the bin directory
if [[ -d $src_bin_dir ]]; then
	# Enable nullglob to avoid matching literal '*' when empty
	shopt -s nullglob
	for file_path in "$src_bin_dir"/*; do
		if [[ -f $file_path ]]; then
			filename=${file_path##*/}
			expected_links["$target_bin_dir/$filename"]=$file_path
		fi
	done
	shopt -u nullglob
else
	log_error "Source bin directory not found at $src_bin_dir"
fi

# 3. Create or update symlinks
manage_symlink() {
	local src=$1
	local target=$2

	if [[ -L $target ]]; then
		local current_link
		current_link=$(readlink "$target")
		if [[ $current_link == "$src" ]]; then
			log_noop "$target -> $src"
			return 0
		else
			rm "$target"
			log_removed "$target (pointed to $current_link)"
		fi
	elif [[ -e $target ]]; then
		log_error "$target exists and is not a symlink. Skipping."
		return 1
	fi

	if ln -s "$src" "$target"; then
		log_new "$target -> $src"
	else
		log_error "Failed to create symlink $target -> $src"
		return 1
	fi
}

for target in "${!expected_links[@]}"; do
	src=${expected_links[$target]}
	manage_symlink "$src" "$target"
done

# 4. Remove stale symlinks pointing to this repository
if [[ -d $target_bin_dir ]]; then
	# Enable nullglob
	shopt -s nullglob
	for target in "$target_bin_dir"/*; do
		if [[ -L $target ]]; then
			link_target=$(readlink "$target")

			# Check if this link points to somewhere in our repository
			if [[ $link_target == "$repo_dir"/* || $link_target == "$repo_dir" ]]; then
				# If it's not one of our expected links, it is stale
				if [[ -z ${expected_links[$target]:-} ]]; then
					rm "$target"
					log_removed "$target (stale link pointing to $link_target)"
				fi
			fi
		fi
	done
	shopt -u nullglob
fi
