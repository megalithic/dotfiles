# mise + fnox shell activation.
if command -q mise
  mise activate fish | source
end

if command -q fnox
  fnox activate fish | source
end
