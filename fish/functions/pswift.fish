function pswift -d "Pretty print pswift"
  bat -l m --tabs 0 -p --theme Nord --wrap=never --pager "less -SR" $argv;
end
