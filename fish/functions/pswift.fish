function pswift -d "Pretty print Swift"
    bat -l swift --tabs 0 -p --theme Nord --wrap=never --pager "less -SR" $argv
end
