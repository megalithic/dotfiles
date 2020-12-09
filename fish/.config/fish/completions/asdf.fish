set -l asdf_dir ~/.asdf
if set -q ASDF_DIR
	set asdf_dir $ASDF_DIR
end

source $asdf_dir/completions/asdf.fish
