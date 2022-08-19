function pstruct -d "Pretty print C struct"
  clang-format -style='{AlignConsecutiveDeclarations: true}' --assume-filename thread.h | bat -l c --tabs 0 -p --theme Nord --wrap=never $argv;
end
