function pdass -d "Pretty print disassembly"
  bat -l s --tabs 0 -p --theme Nord --wrap=never --pager "less -SR" $argv;
end
