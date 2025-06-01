#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup VSCode")"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Create VSCode cli 'code' alias"
ln -sf /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $(brew --prefix)/bin/code

echo "$(gum style --bold --foreground "#BE05D0" "  -") Install VSCode plugins..."
code --install-extension adamhartford.vscode-base64 --force
code --install-extension alefragnani.Bookmarks --force
code --install-extension alexcvzz.vscode-sqlite --force
code --install-extension BeardedBear.beardedtheme --force
code --install-extension bradlc.vscode-tailwindcss --force
code --install-extension charliermarsh.ruff --force
code --install-extension christian-kohler.path-intellisense --force
code --install-extension dnicolson.binary-plist --force
code --install-extension eamodio.gitlens --force
code --install-extension enkia.tokyo-night --force
code --install-extension fill-labs.dependi --force
code --install-extension foxundermoon.shell-format --force
code --install-extension GitHub.copilot --force
code --install-extension GitHub.vscode-codeql --force
code --install-extension github.vscode-github-actions --force
code --install-extension GitHub.vscode-pull-request-github --force
code --install-extension golang.go --force
code --install-extension Gruntfuggly.todo-tree --force
code --install-extension jgclark.vscode-todo-highlight --force
code --install-extension johnpapa.vscode-peacock --force
code --install-extension KevinRose.vsc-python-indent --force
code --install-extension llvm-vs-code-extensions.vscode-clangd --force
code --install-extension mgesbert.python-path --force
code --install-extension miguelsolorio.fluent-icons --force
code --install-extension moshfeu.compare-folders --force
code --install-extension ms-python.black-formatter --force
code --install-extension ms-python.debugpy --force
code --install-extension ms-python.python --force
code --install-extension ms-python.vscode-pylance --force
code --install-extension ms-toolsai.jupyter --force
code --install-extension ms-vscode.atom-keybindings --force
code --install-extension ms-vscode.cpptools-extension-pack --force
code --install-extension ms-vscode.hexeditor --force
code --install-extension njpwerner.autodocstring --force
code --install-extension redhat.vscode-xml --force
code --install-extension redhat.vscode-yaml --force
code --install-extension rust-lang.rust-analyzer --force
code --install-extension spmeesseman.vscode-taskexplorer --force
code --install-extension swiftlang.swift-vscode --force
code --install-extension svelte.svelte-vscode --force
code --install-extension tamasfe.even-better-toml --force
code --install-extension tauri-apps.tauri-vscode --force
code --install-extension tinkertrain.theme-panda --force
code --install-extension trailofbits.sarif-explorer --force
code --install-extension trailofbits.weaudit --force
code --install-extension Tyriar.theme-sapphire --force
code --install-extension vadimcn.vscode-lldb --force
code --install-extension vknabel.vscode-apple-swift-format --force
code --install-extension wesbos.theme-cobalt2 --force
code --install-extension whizkydee.material-palenight-theme --force
code --install-extension wmaurer.change-case --force
code --install-extension YoavBls.pretty-ts-errors --force
code --install-extension yzane.markdown-pdf --force
code --install-extension yzhang.markdown-all-in-one --force
code --install-extension ziglang.vscode-zig --force

echo "$(gum style --bold --foreground "#BE05D0" "  -") Configure VSCode settings..."
cp $(dirname "$0")/vscode_settings.json "$HOME/Library/Application Support/Code/User/settings.json"
