return function(template, replacements)
  return string.gsub(template, '{(.-)}', replacements);
end
