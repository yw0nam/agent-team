# Renders docs/demo.gif: `vhs docs/demo.tape` (needs a configured `impl` role)
Output docs/demo.gif
Set Shell bash
Set FontSize 15
Set Width 1200
Set Height 240
Set Theme "Catppuccin Mocha"
Set TypingSpeed 20ms

Hide
Type `export PS1='$ ' && cd "$(mktemp -d)" && clear`
Enter
Show

Type "agent-send impl demo 'Remember the codeword: pineapple. Reply with the Summary only, one sentence.'"
Enter
Sleep 0.5s
# the model's turn is cut from the recording
Hide
Wait@300s /^\$$/
Show
Sleep 2s

Type "agent-send impl demo 'What was the codeword? Reply with the Summary only, one sentence, from memory.'"
Enter
Sleep 0.5s
Hide
Wait@300s /^\$$/
Show
Sleep 4s
