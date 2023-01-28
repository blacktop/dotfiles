function asn1parse --description 'asn1 dump begining of file'
    openssl asn1parse -i -inform DER -in $argv -dlimit 500 | head -n6
end