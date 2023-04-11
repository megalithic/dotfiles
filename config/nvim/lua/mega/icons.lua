return {
  border = {
    rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    squared = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
    blank = { " ", " ", " ", " ", " ", " ", " ", " " },
  },
  lsp = {
    error = "", -- alts: 
    warn = "", -- alts: 喝卑
    info = "",
    hint = "", -- alts: 
    ok = "",
    -- spinner_frames = { "▪", "■", "□", "▫" },
    -- spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    -- TODO: evaluate
    -- kinds = {
    --   Text = "",
    --   Method = "",
    --   Function = "",
    --   Constructor = "",
    --   Field = "", -- '',
    --   Variable = "", -- '',
    --   Class = "", -- '',
    --   Interface = "",
    --   Module = "",
    --   Property = "ﰠ",
    --   Unit = "塞",
    --   Value = "",
    --   Enum = "",
    --   Keyword = "", -- '',
    --   Snippet = "", -- '', '',
    --   Color = "",
    --   File = "",
    --   Reference = "", -- '',
    --   Folder = "",
    --   EnumMember = "",
    --   Constant = "", -- '',
    --   Struct = "", -- 'פּ',
    --   Event = "",
    --   Operator = "",
    --   TypeParameter = "",
    -- },
    kind = {
      Text = "", -- Text
      Method = "", -- Method
      Function = "", -- Function
      Constructor = "", -- Constructor
      Field = "ﰠ", -- Field
      Variable = "", -- Variable, alts: 
      Class = "", -- Class
      Interface = "ﰮ", -- Interface
      Module = "", -- Module
      Property = "", -- Property
      Unit = "", -- Unit
      Value = "", -- Value
      Enum = "", -- Enum -- alts: 了
      Keyword = "", -- Keyword
      Snippet = "", -- Snippet
      Color = "", -- Color
      File = "", -- File
      Reference = "", -- Reference
      Folder = "", -- Folder
      EnumMember = "", -- EnumMember
      Constant = "", -- Constant
      Struct = "פּ", -- Struct, alts: 
      Event = "鬒", -- Event
      Operator = "\u{03a8}", -- Operator
      TypeParameter = "", -- TypeParameter
      Namespace = "",
      Package = "",
      String = "",
      Number = "",
      Boolean = "",
      Array = "",
      Object = "",
      Key = "",
      Null = "ﳠ",
    },
  },
  kind_highlights = {
    Text = "String",
    Method = "TSMethod",
    Function = "Function",
    Constructor = "TSConstructor",
    Field = "TSField",
    Variable = "TSVariable",
    Class = "TSStorageClass",
    Interface = "Constant",
    Module = "Include",
    Property = "TSProperty",
    Unit = "Constant",
    Value = "Variable",
    Enum = "Type",
    Keyword = "Keyword",
    File = "Directory",
    Reference = "PreProc",
    Constant = "Constant",
    Struct = "Type",
    Snippet = "Label",
    Event = "Variable",
    Operator = "Operator",
    TypeParameter = "Type",
    Namespace = "TSNamespace",
    Package = "Include",
    String = "String",
    Number = "Number",
    Boolean = "Boolean",
    Array = "StorageClass",
    Object = "Type",
    Key = "TSField",
    Null = "ErrorMsg",
    EnumMember = "TSField",
  },
  codicons = {
    Text = "",
    Method = "",
    Function = "",
    Constructor = "",
    Field = "",
    Variable = "",
    Class = "",
    Interface = "",
    Module = "",
    Property = "",
    Unit = "",
    Value = "",
    Enum = "",
    Keyword = "",
    Snippet = "", -- alts: 
    Color = "",
    File = "",
    Reference = "",
    Folder = "",
    EnumMember = "",
    Constant = "",
    Struct = "",
    Event = "",
    Operator = "",
    TypeParameter = "",
  },
  git = {
    add = "", -- alts: 
    change = "",
    mod = "",
    remove = "", -- alts: 
    ignore = "",
    rename = "",
    diff = "",
    repo = "",
    symbol = "", -- alts:  
  },
  documents = {
    file = "",
    files = "",
    folder = "",
    open_folder = "",
  },
  type = {
    array = "",
    number = "",
    object = "",
    null = "[]",
    float = "",
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
  misc = {
    clock = "",
    ellipsis = "…",
    lblock = "▌",
    rblock = "▐",
    bug = "",
    question = "",
    lock = "",
    circle = "",
    project = "",
    dashboard = "",
    history = "",
    comment = "",
    robot = "ﮧ",
    lightbulb = "",
    search = "", -- alts: 
    code = "",
    telescope = "",
    gear = "",
    package = "",
    list = "",
    sign_in = "",
    check = "",
    fire = "",
    note = "",
    bookmark = "",
    pencil = "",
    chevron_right = "",
    table = "",
    calendar = "",
    fold_open = "",
    fold_close = "",
    hydra = "🐙",
  },
  virtual_text = "",
  mode_term = "ﲵ",
  ln_sep = "ℓ", -- alts: ℓ 
  col_sep = "",
  sep = "⋮",
  perc_sep = "",
  modified = "", -- alts: ✿✸✎ ○∘●綠●∘■ □ ▪ ▫● ◯ ◔ ◕ ◌ ◎ ◦ ◆ ◇ ∘∙
  mode = "",
  vcs = "",
  readonly = "",
  prompt = "",
}
