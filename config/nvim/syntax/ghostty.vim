" Vim syntax file
" Language: Ghostty config file
" Maintainer: Ghostty <https://github.com/mitchellh/ghostty>
"
" THIS FILE IS AUTO-GENERATED

if exists('b:current_syntax')
  finish
endif

let b:current_syntax = 'ghostty'

let s:cpo_save = &cpo
set cpo&vim

syn keyword ghosttyConfigKeyword
	\ font-family
	\ font-family-bold
	\ font-family-italic
	\ font-family-bold-italic
	\ font-style
	\ font-style-bold
	\ font-style-italic
	\ font-style-bold-italic
	\ font-feature
	\ font-size
	\ font-variation
	\ font-variation-bold
	\ font-variation-italic
	\ font-variation-bold-italic
	\ font-codepoint-map
	\ font-thicken
	\ adjust-cell-width
	\ adjust-cell-height
	\ adjust-font-baseline
	\ adjust-underline-position
	\ adjust-underline-thickness
	\ adjust-strikethrough-position
	\ adjust-strikethrough-thickness
	\ grapheme-width-method
	\ theme
	\ background
	\ foreground
	\ selection-foreground
	\ selection-background
	\ selection-invert-fg-bg
	\ minimum-contrast
	\ palette
	\ cursor-color
	\ cursor-opacity
	\ cursor-style
	\ cursor-style-blink
	\ cursor-text
	\ cursor-click-to-move
	\ mouse-hide-while-typing
	\ mouse-shift-capture
	\ mouse-scroll-multiplier
	\ background-opacity
	\ background-blur-radius
	\ unfocused-split-opacity
	\ unfocused-split-fill
	\ command
	\ wait-after-command
	\ abnormal-command-exit-runtime
	\ scrollback-limit
	\ link
	\ link-url
	\ fullscreen
	\ title
	\ class
	\ x11-instance-name
	\ working-directory
	\ keybind
	\ window-padding-x
	\ window-padding-y
	\ window-padding-balance
	\ window-inherit-working-directory
	\ window-inherit-font-size
	\ window-decoration
	\ window-title-font-family
	\ window-theme
	\ window-colorspace
	\ window-height
	\ window-width
	\ window-save-state
	\ window-step-resize
	\ window-new-tab-position
	\ gtk-titlebar
	\ clipboard-read
	\ clipboard-write
	\ clipboard-trim-trailing-spaces
	\ clipboard-paste-protection
	\ clipboard-paste-bracketed-safe
	\ image-storage-limit
	\ copy-on-select
	\ click-repeat-interval
	\ config-file
	\ confirm-close-surface
	\ quit-after-last-window-closed
	\ shell-integration
	\ shell-integration-features
	\ osc-color-report-format
	\ vt-kam-allowed
	\ custom-shader
	\ custom-shader-animation
	\ macos-non-native-fullscreen
	\ macos-titlebar-tabs
	\ macos-option-as-alt
	\ gtk-single-instance
	\ gtk-tabs-location
	\ gtk-wide-tabs
	\ gtk-adwaita
	\ desktop-notifications
	\ term
	\ enquiry-response

syn match ghosttyConfigComment /#.*/ contains=@Spell

hi def link ghosttyConfigComment Comment
hi def link ghosttyConfigKeyword Keyword

let &cpo = s:cpo_save
unlet s:cpo_save
