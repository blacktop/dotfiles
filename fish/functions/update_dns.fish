function update_dns --description 'Update DNS block list'
    echo " > Updating DNScrypt-proxy's Blacklist..."
    set -l blockpath $HOME/.config/blocklists
    mkdir -p $blockpath
    wget --show-progress -q 'https://download.dnscrypt.info/blacklists/domains/mybase.txt' -O "$blockpath/mybase.txt"
    wget --show-progress -q 'https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt' -O "$blockpath/hostnames.txt"
    command ls -lahG $blockpath
    echo " > Restarting dnscrypt-proxy..."
    brew services restart dnscrypt-proxy
    echo " > Refreshing DNS cache..."
    sudo killall -HUP mDNSResponder
end
