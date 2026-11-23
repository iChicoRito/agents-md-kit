# Records assets/demo.gif with VHS (https://github.com/charmbracelet/vhs).
# Re-record: GitHub > Actions > "demo gif" > Run workflow.

Output assets/demo.gif

Set Shell "bash"
Set FontSize 15
Set Width 1100
Set Height 860
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set CursorBlink false

# Start in an empty project folder with a short prompt (not recorded).
Hide
Type "export PS1='my-app $ ' && mkdir -p /tmp/my-app && cd /tmp/my-app && clear"
Enter
Sleep 500ms
Show

Type "curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash"
Sleep 600ms
Enter
Sleep 2.5s

# Which agents: move around, then pick "Both".
Up
Sleep 500ms
Up
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 700ms
Enter
Sleep 1.2s

# New or existing: the empty folder is detected as new, so just confirm.
Enter
Sleep 1.2s

# Add PROMPT.md for later: pick "Yes".
Up
Sleep 700ms
Enter

# Download, progress bar, summary.
Sleep 6s
