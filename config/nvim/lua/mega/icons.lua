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
      Text = " text", -- Text
      Method = " method", -- Method
      Function = " function", -- Function
      Constructor = " constructor", -- Constructor
      Field = "ﰠ field", -- Field
      Variable = " variable", -- Variable
      Class = " class", -- Class
      Interface = "ﰮ interface", -- Interface
      Module = " module", -- Module
      Property = " property", -- Property
      Unit = " unit", -- Unit
      Value = " value", -- Value
      Enum = "了enum", -- Enum -- alts: 
      Keyword = " keyword", -- Keyword
      Snippet = " snippet", -- Snippet
      Color = " color", -- Color
      File = " file", -- File
      Reference = " ref", -- Reference
      Folder = " folder", -- Folder
      EnumMember = " enum member", -- EnumMember
      Constant = " const", -- Constant
      Struct = "פּ struct", -- Struct
      Event = "鬒event", -- Event
      Operator = "\u{03a8} operator", -- Operator
      TypeParameter = " type param", -- TypeParameter
      Namespace = " namespace",
      Package = " package",
      String = " string",
      Number = " number",
      Boolean = " boolean",
      Array = " array",
      Object = " object",
      Key = " key",
      Null = "ﳠ null",
    },
  },
  kind_highlights = {
    Text = "String",
    Method = "Method",
    Function = "Function",
    Constructor = "TSConstructor",
    Field = "Field",
    Variable = "Variable",
    Class = "Class",
    Interface = "Constant",
    Module = "Include",
    Property = "Property",
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
    Package = "Package",
    String = "String",
    Number = "Number",
    Boolean = "Boolean",
    Array = "Array",
    Object = "Object",
    Key = "Key",
    Null = "Null",
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
  },
  virtual_text = "",
  mode_term = "ﲵ",
  ln_sep = "ℓ", -- alts: ℓ 
  col_sep = "",
  sep = "⋮",
  perc_sep = "",
  modified = "○", -- alts: ○●綠
  mode = "",
  vcs = "",
  readonly = "",
  prompt = "",
}
