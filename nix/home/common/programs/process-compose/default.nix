_: {
  xdg.configFile."process-compose/shortcuts.yaml".text = ''
    shortcuts:
      log_follow:
        shortcut: Ctrl-F
        toggle_description:
          false: Follow Off
          true: Follow On
      log_screen:
        shortcut: Ctrl-L
        toggle_description:
          false: Half Screen
          true: Full Screen
      log_wrap:
        shortcut: Ctrl-W
        toggle_description:
          false: Wrap Off
          true: Wrap On
      process_restart:
        shortcut: Ctrl-R
        description: Restart
      process_screen:
        shortcut: Ctrl-P
        toggle_description:
          false: Half Screen
          true: Full Screen
      process_start:
        shortcut: Ctrl-S
        description: Start
      process_stop:
        shortcut: Ctrl-X
        description: Stop
      quit:
        shortcut: Ctrl-Q
        description: Quit
  '';

  xdg.configFile."process-compose/theme.yaml".text = ''
    style:
      body:
        bgColor: '#2e353c'
        fgColor: '#d3c6aa'
        borderColor: '#475258'
        secondaryTextColor: '#859289'
        tertiaryTextColor: '#7a8478'
      stat_table:
        keyFgColor: '#a7c080'
        valueFgColor: '#d3c6aa'
        logoColor: '#7fbbb3'
      proc_table:
        fgColor: '#d3c6aa'
        fgWarning: '#dbbc7f'
        fgPending: '#7fbbb3'
        fgCompleted: '#a7c080'
        fgError: '#e67e80'
      help:
        fgColor: '#d3c6aa'
        keyColor: '#a7c080'
      dialog:
        bgColor: '#343f44'
        fgColor: '#d3c6aa'
        buttonBgColor: '#475258'
        buttonFgColor: '#d3c6aa'
        labelFgColor: '#a7c080'
        fieldBgColor: '#2e353c'
        fieldFgColor: '#d3c6aa'
  '';
}
