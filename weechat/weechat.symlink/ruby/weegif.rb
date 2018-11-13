require "digest"
require "uri"

#
#		WEEGIF
#		Ruby script to render image urls inline using iTerm2-nightly + imgcat.
#   Requires imgcat and iTerm2-nightly
#

#
#		Author: Seth Messer aka megalithic aka replicant
#		Email: seth.messer@gmail.com
#

#
# Copyright (c) 2016 Seth Messer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

SCRIPT_NAME = 'weegif'
SCRIPT_AUTHOR = 'Seth Messer <seth.messer@gmail.com>'
SCRIPT_DESC = 'Capture image urls and render them inline using iTerm2-nightly + imgcat.'
SCRIPT_VERSION = '0.1'
SCRIPT_LICENSE = 'MIT'

DEFAULTS = {
  'maxlen' => '0',
  'color' => 'red',
  'tmpdir' => File.expand_path("~/tmp")
}

def weechat_init
  Weechat.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE, SCRIPT_DESC, "", "")
  Weechat.hook_command(SCRIPT_NAME, SCRIPT_DESC, "url", "url: url image to render", "", "fetch_image", "")

  # Weechat.hook_print("", "notify_message", "://", 1, "fetch_image", "")
  # Weechat.hook_print("", "notify_private", "://", 1, "fetch_image", "")
  # Weechat.hook_print("", "notify_highlight", "://", 1, "fetch_image", "")
  # Weechat.hook_print("", "notify_none", "://", 1, "fetch_image", "")

  set_defaults

  current_window_print "[weegif] image renderer firing up.."

	Weechat::WEECHAT_RC_OK
end

def fetch_image (data, buffer, time, tags, displayed, highlight, prefix, message)
  if (message.empty?)
    return Weechat::WEECHAT_RC_OK
  end

  matchdata = message.match(image_url_regex)
  return Weechat::WEECHAT_RC_OK unless matchdata

  @cmd_buffer = buffer
  @cmd_send_to_buffer = "current"
  @url = matchdata[0].to_s
  image = stored_image if @url

  # width  = `tput cols`.to_i if url
  # height = `tput lines`.to_i if url
  color = Weechat.color(Weechat.config_get_plugin("color"))

  Weechat.print(@cmd_buffer, "[weegif]:\t%s%s (%s)" % [color, @url, image]) if @url
  Weechat.hook_process("wget -O #{image} #{@url}", timeout, "handle_fetched_image", image)

  return Weechat::WEECHAT_RC_OK
end

def handle_fetched_image (data, command, rc, out, err)
  if rc == Weechat::WEECHAT_HOOK_PROCESS_ERROR || err != ''
    # Weechat.print("", "Unable to fetch the image: err: #{err}\n data: #{data}\n command: #{command}\n rc: #{rc}\n out: <supressed>\r\n--------------------------------------\r\n")

    # Weechat.print(@cmd_buffer, "[weegif] ERROR: trying to handled fetched image")
    Weechat.hook_process("imgcat #{data}", timeout, "handle_rendered_image", "") if rc.to_i >= 0
    return Weechat::WEECHAT_RC_ERROR
  end

  # Weechat.print("", "Successful fetch: data: #{data}\n command: #{command}\n rc: #{rc}\n out: <supressed>\r\n--------------------------------------\r\n")

  # Weechat.hook_process("imgcat #{data}", timeout, "handle_rendered_image", "") if rc.to_i >= 0
  Weechat.print(@cmd_buffer, "[weegif] SUCCESS: handling fetched image")
  return Weechat::WEECHAT_RC_OK
end

def handle_rendered_image (data, command, rc, out, err)
  if rc == Weechat::WEECHAT_HOOK_PROCESS_ERROR || err != ''
    Weechat.print("", "Unable to render the image: err: #{err}\r\n")
    # Weechat.print("", "Unable to render the image: err: #{err}\n data: #{data}\n command: #{command}\n rc: #{rc}\n out: <supressed>\r\n--------------------------------------\r\n")
    return Weechat::WEECHAT_RC_ERROR
  end

  # if out
  #   lines = out.rstrip.split('\n')
  # end

  # lines.each do |line|
  #   # Weechat.command("", line) # Weechat.command(@cmd_buffer, line)
  #   # Weechat.print("", "Command '#{data}' (rc #{rc.to_i}), stdout: #{out}; line: #{line}") if rc.to_i >= 0
  # end

  # lines.each do |line|
  #   Weechat.print(@cmd_buffer, " \t#{line}")
  # end

  # Weechat.print("", "Successful render: data: #{data}\n command: #{command}\n rc: #{rc}\n out: <supressed>\r\n--------------------------------------\r\n") if rc.to_i >= 0

  Weechat.print(@cmd_buffer, out)

  return Weechat::WEECHAT_RC_OK
end

## private

def set_defaults
  DEFAULTS.each_pair { |option, def_value|
    cur_value = Weechat.config_get_plugin(option)
    if cur_value.nil? || cur_value.empty?
      Weechat.config_set_plugin(option, def_value)
    end
  }
end

def get_config_string(string)
  option = Weechat.config_get(string)
  Weechat.config_string(option)
end

def current_window_print (str)
  Weechat.print(Weechat.current_buffer, str.to_s)
end

def image_url_regex
  @image_url_regex ||= Regexp.new('https?://.*\.(jpeg|jpg|gif|png)$')
  @image_url_regex
end

def image_url_md5
  md5 = Digest::MD5.new
  md5.update @url
  md5.hexdigest
end

def tmp_folder
  Weechat.config_get_plugin("tmpdir")
end

def stored_image
  "#{tmp_folder}/#{file_name}#{file_extension}".gsub("//", "/")
end

def full_file_name
  @url.match(/[\w:]+\.(jpg|jpeg|png|gif)/i).to_a.first
end

def file_name
  File.basename(full_file_name, File.extname(full_file_name))
end

def file_extension
  File.extname(URI.parse(@url).path)
end

def timeout
  30 * 1000
end

#  vim: set ts=2 sw=2 tw=0 :
