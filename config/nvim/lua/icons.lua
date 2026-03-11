-- lua/icons.lua
-- Centralized icon definitions for nvim_next
-- Ported from ~/.dotfiles/config/nvim/lua/config/icons.lua

return {
  lsp = {
    error = "", -- alts:  󰬌      
    warn = "󰔷", -- alts: 󰬞 󰔷   ▲ 󰔷  󰲉
    info = "", -- alts: 󰖧 󱂈 󰋼  󰙎   󰬐 󰰃     ● 󰬐  ∙  󰌶
    hint = "▫", -- alts:  󰬏 󰰀  󰰂 󰰂 󰰁 󰫵 󰋢    ∴
    ok = "✓", -- alts: ✓✓
    clients = "", -- alts:     󱉓 󱡠 󰾂 
  },

  test = {
    passed = "", --alts: 
    failed = "", --alts: 
    running = "",
    skipped = "○",
    unknown = "", -- alts: 
  },

  vscode = {
    Text = "󰉿 ",
    Method = "󰆧 ",
    Function = "󰊕 ",
    Constructor = " ",
    Field = "󰜢 ",
    Variable = "󰀫 ",
    Class = "󰠱 ",
    Interface = " ",
    Module = " ",
    Property = "󰜢 ",
    Unit = "󰑭 ",
    Value = "󰎠 ",
    Enum = " ",
    Keyword = "󰌋 ",
    Snippet = " ",
    Color = "󰏘 ",
    File = "󰈙 ",
    Reference = "󰈇 ",
    Folder = "󰉋 ",
    EnumMember = " ",
    Constant = "󰏿 ",
    Struct = "󰙅 ",
    Event = " ",
    Operator = "󰆕 ",
    TypeParameter = " ",
  },

  kind = {
    Array = "",
    Boolean = "",
    Class = "󰠱",
    Codeium = "",
    Color = "󰏘",
    Constant = "󰏿",
    Constructor = "",
    Enum = "", -- alts:
    EnumMember = "", -- alts:
    Event = "",
    Field = "󰜢",
    File = "󰈙",
    Folder = "󰉋",
    Function = "󰊕",
    Interface = "",
    Key = "",
    Keyword = "󰌋",
    Method = "",
    Module = "",
    Namespace = "",
    Null = "󰟢", -- alts: 󰱥󰟢
    Number = "󰎠", -- alts:
    Object = "",
    Operator = "󰆕",
    Package = "",
    Property = "󰜢",
    Reference = "󰈇",
    Snippet = "", -- alts:
    String = "", -- alts:  󱀍 󰀬 󱌯
    Struct = "󰙅",
    Text = "󰉿",
    TypeParameter = "",
    Unit = "󰑭",
    Value = "󰎠",
    Variable = "󰀫",
  },

  separators = {
    thin_block = "│",
    left_thin_block = "▏",
    vert_bottom_half_block = "▄",
    vert_top_half_block = "▀",
    right_block = "🮉",
    right_med_block = "▐",
    light_shade_block = "░",
  },

  pi = {
    symbol = "π", -- Main pi icon (matches pi-coding-agent)
    connected = "π", -- Connected to socket
    disconnected = "∅", -- No socket found
    context = "◆", -- Has context files
  },

  jj = {
    symbol = "◇", -- Jujutsu icon
    conflict = "", -- Conflict indicator
    bookmark = "", -- Bookmark/branch icon
  },

  misc = {
    formatter = "", -- alts: 󰉼
    buffers = "",
    clock = "",
    ellipsis = "…",
    lblock = "▌",
    rblock = "▐",
    bug = "", -- alts: 
    question = "",
    lock = "󰌾", -- alts:   
    shaded_lock = "",
    circle = "",
    project = "",
    dashboard = "",
    history = "󰄉",
    comment = "󰅺",
    robot = "󰚩", -- alts: 󰭆
    lightbulb = "󰌵",
    file_tree = "󰙅",
    help = "󰋖", -- alts: 󰘥 󰮥 󰮦 󰋗 󰞋 󰋖
    search = "", -- alts: 󰍉
    exit = "󰈆", -- alts: 󰩈󰿅
    code = "",
    telescope = "",
    terminal = "", -- alts: 
    gear = "",
    package = "",
    list = "",
    sign_in = "",
    check = "✓", -- alts: ✓
    fire = "",
    note = "󰎛",
    bookmark = "",
    pencil = "󰏫",
    arrow_right = "",
    caret_right = "",
    chevron_right = "",
    r_chev = "",
    double_chevron_right = "»",
    table = "",
    calendar = "",
    fold_open = "",
    fold_close = "",
    hydra = "🐙",
    flames = "󰈸", -- alts: 󱠇󰈸
    vsplit = "◫",
    v_border = "▐ ",
    virtual_text = "◆",
    mode_term = "",
    ln_sep = "≡", -- alts: ≡ ℓ 
    ln_sel = "",
    sep = "⋮",
    perc_sep = "",
    modified = "", -- alts: ∘✿✸✎ ○∘●●∘■ □ ▪ ▫● ◯ ◔ ◕ ◌ ◎ ◦ ◆ ◇ ▪▫◦∘∙⭘
    mode = "",
    vcs = "",
    readonly = "",
    prompt = "",
    markdown = {
      h1 = "◉", -- alts: 󰉫¹◉
      h2 = "◆", -- alts: 󰉬²◆
      h3 = "󱄅", -- alts: 󰉭³✿
      h4 = "⭘", -- alts: 󰉮⁴○⭘
      h5 = "◌", -- alts: 󰉯⁵◇◌
      h6 = "", -- alts: 󰉰⁶
      dash = "",
    },
  },

  git = {
    -- add = "▕", -- alts:  ▕,▕, ▎, ┃, │, ▌, ▎ 🮉
    -- change = "🮉", -- alts:  ▕ ▎║▎ ▀, ▁, ▂, ▃, ▄, ▅, ▆, ▇, █, ▉, ▊, ▋, ▌, ▍, ▎, ▏, ▐
    -- delete = "█", -- alts: ┊▎▎
    -- topdelete = "▀",
    -- changedelete = "▄",
    -- untracked = "▕",
    -- mod = "",
    -- remove = "", -- alts:
    -- ignore = "",
    -- rename = "",
    -- diff = "",
    -- repo = "",
    -- symbol = "", -- alts:
    -- unstaged = "󰛄",
    -- branch = "",
    -- added = "+",
    -- removed = "-",
    -- changed = "~",

    add = "▕", -- alts:  ▕,▕, ▎, ┃, │, ▌, ▎ 🮉
    change = "🮉", -- alts:  ▕ ▎║▎ ▀, ▁, ▂, ▃, ▄, ▅, ▆, ▇, █, ▉, ▊, ▋, ▌, ▍, ▎, ▏, ▐
    delete = "█", -- alts: ┊▎▎
    topdelete = "▀",
    changedelete = "▄",
    untracked = "▕",
    mod = "",
    remove = "", -- alts: 
    ignore = "",
    rename = "",
    diff = "",
    repo = "",
    symbol = "", -- alts:  
    unstaged = "󰛄",
    branch = "",
    added = "+",
    removed = "-",
    changed = "~",
  },
}
