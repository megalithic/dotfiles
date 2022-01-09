# Use the solarized pry theme
Pry.config.theme = "solarized"

# Use MacVim as an interactive editor
Pry.config.editor = "nvim"

if defined?(Rails)
  # Use the current rails app name for the pry prompt
  Pry.config.prompt_name = Rails.application.class.parent_name.to_s.underscore.titleize
else
  # Use the current directory name for the pry prompt
  Pry.config.prompt_name = Dir.pwd.split('/').last
end


class Object
  # returns a list of the object's methods, *without* all the usual ones
  # example: some_object.my_methods
  def my_methods
    base_object = case self
                  when Class  then Class.new
                  when Module then Module.new
                  else             Object.new
                  end
    (methods - base_object.methods).sort
  end

  # The w stands for "where"
  # example: some_object.wtf?(:some_method)
  def wtf?(name)
    if m = method(name)
      m.source_location.join(':') if m.source_location
    end
  end

end

module Enumerable
  # like `uniq`, but returns a hash of element => count pairs
  # (much like `uniq -c` at the command line)
  def uniq_c
    Hash.new{|h,k| h[k] = 0}.tap do |result|
      each{|k| result[k] += 1}
    end
  end

  # like `uniq_c`, but returns an array of nicely printable strings rather than the hash
  # (works nicely as an argument to `puts`)
  def uniq_n
    uniq_c.sort_by(&:second).map{|k,c| "#{c}: #{k}"}
  end
end

# alias for _
def last
  eval("_", Pry.toplevel_binding)
end

# Don't potentially execute shell commands when pasting multi-line method call chains
Pry.commands.delete '.<shell command>'

# ------------------------------ Brainy-specific stuff

# Finds the matching user and sets `u` and `p` variables
# _user "glenn@first.io"
# _user "glenn vanderburg"
# _user 124
def _user(*args)
  if args.count > 2
    puts "I don't know what to do with more than 2 arguments"
    return
  end

  key = args[0]
  key.strip! if key.is_a?(String)
  case
  when args.count == 2
    u = User.find_by(first_name: key, last_name: args[1].strip)
  when key.is_a?(Integer) || key =~ /^\d+$/
    u = User.find_by(id: key)
  when key =~ /@/
    u = User.find_by(email: key)
  else
    # case-insensitive match against full_name:
    parts = key.split
    # Postgres regular expressions use \y instead of \b
    pattern = '\y' + parts.map(&:downcase).join('\y.*\y') + '\y'
    u = User.find_by("full_name ~* '#{pattern}'")
  end

  if u.nil?
    puts "Couldn't find a matching user"
    return
  end

  puts "Setting u and p based on user #{u.id}, #{u.full_name}"
  Pry.toplevel_binding.eval("u = User.find(#{u.id}); p = u.person"); nil
end
