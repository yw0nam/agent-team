# Renders docs/demo.gif: `vhs docs/demo.tape` (needs a configured `impl` role)
Output docs/demo.gif
Set Shell bash
Set FontSize 15
Set Width 1100
Set Height 420
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms

Hide
Type `export PS1='$ ' && cd "$(mktemp -d)" && clear`
Enter
Show

Type "agent-send --roles"
Enter
Sleep 1.5s

Type "agent-send impl demo 'Remember the codeword: pineapple. Reply with the Summary section only.'"
Enter
Wait@300s /^\$$/
Sleep 2s

Type "agent-send impl demo 'What codeword did I give you? Summary section only.'"
Enter
Wait@300s /^\$$/
Sleep 2s

Type "agent-send --list"
Enter
Sleep 3s
