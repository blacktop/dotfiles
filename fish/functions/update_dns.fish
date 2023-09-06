function update_dns --description 'Update DNS block list'
    echo " > Updating DNScrypt-proxy's Blacklist..."
	set -l BLOCKPATH $HOME/.config/blocklists
    mkdir -p $BLOCKPATH
	wget --show-progress -q 'https://download.dnscrypt.info/blacklists/domains/mybase.txt' -O "$BLOCKPATH/mybase.txt"
	wget --show-progress -q 'https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt' -O "$BLOCKPATH/hostnames.txt"
	command ls --color -lah $BLOCKPATH
    echo " > Restarting dnscrypt-proxy..."
	brew services restart dnscrypt-proxy
    echo " > Refreshing DNS cache..."
    sudo killall -HUP mDNSResponder
end