#!/bin/bash

# Config
port=80
urlscheme=http
curlflag=
domain=
root=
startdate="`date +"%d-%m-%Y %H:%M:%S"`"
dir=
wordlist="/usr/share/wordlists/wfuzz/general/megabeast.txt"

# script
usage() {
echo -e "Usage: $0 [-d] <domain>" 1>&2; exit 1;
}

while getopts ":sdh:" o; do
    case "${o}" in
	:)
		echo "Option -$OPTARG requires an argument."
		;;
	d | h)
       		domain=${OPTARG}
            	;;
        #s)
         #   urlscheme=https
	  #  curlflag=-k
	   # port=443
            #;;
	*)
            	usage
            	;;
    esac
done
shift $((OPTIND-1))

if [ -z "${domain}" ] ; then
   if [ -z "$1" ]
   then
       	usage
else
domain=$1
fi
fi

if [[ $domain =~ ^"https://"* ]]
then
	urlscheme=https
	curlflag=-k
	port=443
fi
domain=`echo $domain | sed "s/^$urlscheme:\/\///g"`

mdir() {
 mkdir "$1" 2>/dev/null 1>/dev/null
}

getsubdomains(){ # to be implemented
  python ~/tools/Sublist3r/sublist3r.py -d $domain -t 10 -v -o ./$domain/$foldername/$domain.txt #make var for path
  curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $domain >> "$dir/$domain.txt"
}


screenshot(){ # to be implemented
    echo "taking a screenshot of $line"
    python ~/tools/webscreenshot/webscreenshot.py -o ./$domain/$foldername/screenshots/ -i ./$domain/$foldername/responsive-$(date +"%Y-%m-%d").txt --timeout=10 -m
}


dowfuzz() {
	wfuzz -f "$dir/wfuzz.html",html -w $wordlist -c -L -R 5 -Z --filter "c!=404" -u $urlscheme"://"$1/FUZZ
}

niktoscan() {
	nikto -host $urlscheme"://"$1 -port $2 -Format html -output "$dir/nikto.html"
}


recon() {
# start the script here
niktoscan $1 $2
dowfuzz $1

}

main() {
if (curl -X HEAD $curlflag -i -s $domain 2>/dev/null 1>/dev/null) then #optimize that it only gets the head
	echo "Connected to $domain"
	mdir "$domain"
	mdir "$domain/$startdate"
	dir="$domain/$startdate"
	recon $domain $port
else
	echo "cannot connect to $domain"
fi
}

main $domain
