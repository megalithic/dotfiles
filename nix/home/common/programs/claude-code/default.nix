{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    settings = {
      theme = "dark";
      autoUpdates = false;
      includeCoAuthoredBy = false;
      autoCompactEnabled = false;
      enableAllProjectMcpServers = true;
      feedbackSurveyState.lastShownTime = 1754089004345;
      outputStyle = "Explanatory";
      model = "claude-opus-4-7";
    };
  };
}
