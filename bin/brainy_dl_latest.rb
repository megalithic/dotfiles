#!/usr/bin/env ruby
# -*-ruby-*-

# Download the most recent compact Brainy backup

case ARGV.size
when 0 then destination = nil
when 1 then destination = ARGV[0]
else $stderr.puts "Usage: #{$0} [destination_directory]" and die
end

Dir.chdir(destination) if destination

def get_backup_filename
  cmds = <<~'EOS'
    aws s3 ls s3://first-io-backup/production/ | \
    egrep '\bpostgresql-compact-backup-.*\.dump' | \
    tail -1 | \
    sed -e 's/^.* //'
  EOS
  %x(#{cmds}).chomp
end

puts "Looking for latest brainy compact backup ..."
s3_file = get_backup_filename

backup_date = s3_file[/\d{4}-\d{2}-\d{2}/]

puts "Downloading compact backup for #{backup_date}."
system "aws s3 cp 's3://first-io-backup/production/#{s3_file}' ."

# Grab a list of already-downloaded backups to prompt for deletion
# later (but don't include the one we're downloading; it might be there
# if this is a retry after a failed download attempt).
existing_backups = open("|ls postgresql-*.dump | fgrep -v '#{s3_file}'", "r"){|pipe| pipe.readlines}.map(&:chomp)

unless existing_backups.empty?
  puts "Removing old backups:"
  system "rm -i #{existing_backups.join(' ')}"
end

path = if destination.nil?
         s3_file
       else
         File.join(destination, s3_file)
       end
open("|pbcopy", "w"){|pipe| pipe.puts path }
puts "The dump filename has been copied to the clipboard."
