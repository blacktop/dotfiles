function update_dns --description 'Update DNS block list'
    echo " > Updating DNScrypt-proxy's Blacklist..."
    set -l blockpath $HOME/.config/blocklists
    mkdir -p $blockpath
    set -l mybase_tmp "$blockpath/mybase.txt.tmp"
    wget --show-progress -q 'https://download.dnscrypt.info/blacklists/domains/mybase.txt' -O "$mybase_tmp"; or begin; command rm -f "$mybase_tmp"; return 1; end
    set -l hostnames_tmp "$blockpath/hostnames.txt.tmp"
    wget --show-progress -q 'https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt' -O "$hostnames_tmp"; or begin; command rm -f "$mybase_tmp" "$hostnames_tmp"; return 1; end
    command mv "$mybase_tmp" "$blockpath/mybase.txt"; or begin; command rm -f "$mybase_tmp" "$hostnames_tmp"; return 1; end
    command mv "$hostnames_tmp" "$blockpath/hostnames.txt"; or begin; command rm -f "$hostnames_tmp"; return 1; end
    command ls -lahG $blockpath
    echo " > Restarting dnscrypt-proxy..."
    brew services restart dnscrypt-proxy
    echo " > Refreshing DNS cache..."
    sudo killall -HUP mDNSResponder
end
