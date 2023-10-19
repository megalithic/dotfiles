return {
  border = {
    rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    squared = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
    blank = { " ", " ", " ", " ", " ", " ", " ", " " },
  },
  lsp = {
    error = "", -- alts: 
    warn = "󰔷", -- alts: 
    info = "", -- alts: 󰋼  ℹ 󰙎 
    hint = "", -- alts: 󰌶
    ok = "✓", -- alts: ✓
    -- spinner_frames = { "▪", "■", "□", "▫" },
    -- spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    -- TODO: evaluate
    kind = {

      Array = "",
      Boolean = "",
      Class = "󰠱",
      -- Class = "", -- Class
      Color = "󰏘",
      -- Color = "", -- Color
      Constant = "󰏿",
      -- Constant = "", -- Constant
      Constructor = "",
      -- Constructor = "", -- Constructor
      Enum = "",
      -- Enum = "", -- Enum -- alts: 了
      EnumMember = "",
      -- EnumMember = "", -- EnumMember
      Event = "",
      Field = "󰜢",
      File = "󰈙",
      -- File = "", -- File
      Folder = "󰉋",
      -- Folder = "", -- Folder
      Function = "󰊕",
      Interface = "",
      Key = "",
      Keyword = "󰌋",
      -- Keyword = "", -- Keyword
      Method = "",
      Module = "",
      Namespace = "",
      Null = "󰟢", --alts: 󰟢ﳠ
      Number = "",
      Object = "",
      -- Operator = "\u{03a8}", -- Operator
      Operator = "󰆕",
      Package = "",
      Property = "󰜢",
      -- Property = "", -- Property
      Reference = "󰈇",
      Snippet = "",
      String = "", -- alts: 
      Struct = "󰙅",
      Text = "󰉿",
      TypeParameter = "",
      Unit = "󰑭",
      -- Unit = "", -- Unit
      Value = "󰎠",
      Variable = "󰀫",
      -- Variable = "", -- Variable, alts: 

      -- Text = "",
      -- Method = "",
      -- Function = "",
      -- Constructor = "",
      -- Field = "",
      -- Variable = "",
      -- Class = "",
      -- Interface = "",
      -- Module = "",
      -- Property = "",
      -- Unit = "",
      -- Value = "",
      -- Enum = "",
      -- Keyword = "",
      -- Snippet = "",
      -- Color = "",
      -- File = "",
      -- Reference = "",
      -- Folder = "",
      -- EnumMember = "",
      -- Constant = "",
      -- Struct = "",
      -- Event = "",
      -- Operator = "",
      -- TypeParameter = "",
    },
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
    symbol = "", -- alts:  
  },
  documents = {
    file = "",
    files = "",
    folder = "",
    open_folder = "",
  },
  test = {
    passed = "", --alts: 
    failed = "", --alts: 
    running = "",
    skipped = "○",
    unknown = "", -- alts: 
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
    bug = "", -- alts: 
    question = "",
    lock = "",
    shaded_lock = "",
    circle = "",
    project = "",
    dashboard = "",
    history = "󰄉",
    comment = "󰅺",
    robot = "󰚩",
    lightbulb = "󰌵",
    search = "", -- alts: 󰍉
    code = "",
    telescope = "",
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
    double_chevron_right = "»",
    table = "",
    calendar = "",
    fold_open = "",
    fold_close = "",
    hydra = "🐙",
    flames = "󰈸", -- alts: 󱠇󰈸
  },
  more = {
    abc = "  ",
    array = "  ",
    arrowReturn = "  ",
    bigCircle = "  ",
    bigUnfilledCircle = "  ",
    bomb = "  ",
    bookMark = "  ",
    boolean = "  ",
    box = " 󰅫 ",
    buffer = "  ",
    bug = "  ",
    calculator = "  ",
    calendar = "  ",
    caretRight = "",
    checkSquare = "  ",
    copilot = "",
    codeium = "",
    exit = " 󰗼 ",
    chevronRight = "",
    circle = "  ",
    class = "  ",
    close = "  ",
    code = "  ",
    cog = "  ",
    color = "  ",
    comment = "  ",
    constant = "  ",
    constructor = "  ",
    container = "  ",
    console = " 󰞷 ",
    consoleDebug = "  ",
    cubeTree = "  ",
    dashboard = "  ",
    database = "  ",
    enum = "  ",
    enumMember = "  ",
    error = "  ",
    errorOutline = "  ",
    errorSlash = " ﰸ ",
    event = "  ",
    field = "  ",
    file = "  ",
    fileBg = "  ",
    fileCopy = "  ",
    fileCutCorner = "  ",
    fileNoBg = "  ",
    fileNoLines = "  ",
    fileNoLinesBg = "  ",
    fileRecent = "  ",
    fire = "  ",
    folder = "  ",
    folderNoBg = "  ",
    folderOpen = "  ",
    folderOpen2 = " 󰉖 ",
    folderOpenNoBg = "  ",
    forbidden = " 󰍛 ",
    func = "  ",
    gear = "  ",
    gears = "  ",
    git = "  ",
    gitAdd = "  ",
    gitChange = " 󰏬 ",
    gitRemove = "  ",
    hexCutOut = "  ",
    history = "  ",
    hook = " ﯠ ",
    info = "  ",
    infoOutline = "  ",
    interface = "  ",
    key = "  ",
    keyword = "  ",
    light = "  ",
    lightbulb = "  ",
    lightbulbOutline = "  ",
    list = "  ",
    lock = "  ",
    m = " m ",
    method = "  ",
    module = "  ",
    newFile = "  ",
    note = " 󰎚 ",
    number = "  ",
    numbers = "  ",
    object = "  ",
    operator = "  ",
    package = " 󰏓 ",
    packageUp = " 󰏕 ",
    packageDown = " 󰏔 ",
    paint = "  ",
    paragraph = " 󰉢 ",
    pencil = "  ",
    pie = "  ",
    pin = " 󰐃 ",
    project = "  ",
    property = "  ",
    questionCircle = "  ",
    reference = "  ",
    ribbon = " 󰑠 ",
    robot = " 󰚩 ",
    scissors = "  ",
    scope = "  ",
    search = "  ",
    settings = "  ",
    signIn = "  ",
    snippet = "  ",
    sort = "  ",
    spell = " 暈",
    squirrel = "  ",
    stack = "  ",
    string = "  ",
    struct = "  ",
    table = "  ",
    tag = "  ",
    telescope = "  ",
    terminal = "  ",
    text = "  ",
    threeDots = " 󰇘 ",
    threeDotsBoxed = "  ",
    timer = "  ",
    trash = "  ",
    tree = "  ",
    treeDiagram = " 󰙅 ",
    typeParameter = "  ",
    unit = "  ",
    up_hexagon = " 󰋘 ",
    value = "  ",
    variable = "  ",
    warningCircle = "  ",
    vim = "  ",
    warningTriangle = "  ",
    warningTriangleNoBg = "  ",
    watch = "  ",
    word = "  ",
    wrench = "  ",
  },
  virtual_text = "",
  mode_term = "ﲵ",
  ln_sep = "ℓ", -- alts: ℓ 
  col_sep = "",
  sep = "⋮",
  perc_sep = "",
  modified = "", -- alts: ✿✸✎ ○∘●綠●∘■ □ ▪ ▫● ◯ ◔ ◕ ◌ ◎ ◦ ◆ ◇ ∘∙
  mode = "",
  vcs = "",
  readonly = "",
  prompt = "",
}
