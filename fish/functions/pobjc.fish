function pobjc -d "Pretty print ObjC"
  bat -l m --tabs 0 -p --theme Nord --wrap=never --pager "less -SR" $argv;
end
