function pmd -d "Pretty print Markdown"
  bat -l md --tabs 0 -p --theme Nord --wrap=never --pager "less -SR" $argv;
end
