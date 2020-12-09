set -l asdf_dir ~/.asdf
if set -q ASDF_DIR
	set asdf_dir $ASDF_DIR
end

if not test -d $asdf_dir
	git clone https://github.com/asdf-vm/asdf.git $asdf_dir
end

source $asdf_dir/asdf.fish
