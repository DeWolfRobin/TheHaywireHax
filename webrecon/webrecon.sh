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
bburp=true


mdir() {
 mkdir "$1" 2>/dev/null 1>/dev/null
} # works

dnsscan (){
  dnsrecon -d $domain -D "/usr/share/wordlists/dnsmap.txt" -t axfr -j "`pwd`/$dir/dnsinfo.json"
} #works

eyewithness () {
  echo "blank"
} #To be implemented

spoofcheck () {
  ../submodules/spoofcheck/spoofcheck.py $domain > "$dir/$domain-spoof.txt"
} #works

getsubdomains(){
  python ~/tools/Sublist3r/sublist3r.py -d $domain -t 10 -v -o "./$dir/$domain-domains.txt"
  curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $domain >> "$dir/$domain-domains.txt"
  knockpy $domain -j
  mv *.json "./$dir/"
} #works

screenshot(){
    echo "taking a screenshot of $line"
    python ~/tools/webscreenshot/webscreenshot.py -o ./$domain/$foldername/screenshots/ -i ./$domain/$foldername/responsive-$(date +"%Y-%m-%d").txt --timeout=10 -m
} #To be implemented

dowfuzz() {
	wfuzz -f "$dir/wfuzz/$1.html",html -w $wordlist -t 10 -c -L -R 5 -Z --filter "c!=404" -u "$urlscheme://$1/FUZZ"
} #works

niktoscan() {
	nikto -host $urlscheme"://"$1 -port $2 -Format html -output "$dir/nikto/$1.html"
} #works

burpstartup() {
  java -Xbootclasspath/p:/lib/decoder_new.jar -jar /lib/burp-rest-api-2.0.1.jar --headless.mode=true --burp.jar=/lib/burpsuite_pro_v2.0beta.jar --project-file="$dir/$1.burp" 1>/dev/null 2>/dev/null &
  echo "Waiting for burp"
  while [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 "http://localhost:8090/v2/api-docs") = 000 ]
  do
    echo "Waiting for burp"
    sleep 0.5
  done
  echo "Done"
  echo "Adding $urlscheme://$1 to the scope"
  curl -X PUT "http://localhost:8090/burp/target/scope?url=$urlscheme://$1"
} #To be implemented

burprecon() {
  echo "Adding $urlscheme://$1 to spider"
  http POST "http://localhost:8090/burp/spider?baseUrl=$urlscheme://$1" 1>/dev/null
  while [ `http "http://localhost:8090/burp/spider/status" | jq -r ".spiderPercentage"` != 100 ]
  do
    echo "hi"
  done
} #To be implemented

# script
usage() {
echo -e "Usage:\n\t$0 [-d] <domain>\n\nOptions:\n\t-b\t\t Disable burpsuite scan" 1>&2; exit 1;
}

while getopts ":fbdh:" o; do
    case "${o}" in
	#:)
	#	echo "Option -$OPTARG requires an argument."
	#	;;
  h)
       		usage
            	;;
	d)
       		domain=${OPTARG}
            	;;
  b)
          bburp=false
	          ;;
  f)
          "$2"
	          ;;
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


recon() {
  echo ""
  # Parameth has build errors
  # Recon-ng
  # Aquatone
# waybackurls.py => mhmdiaa
# waybackrobots.py => mhmdiaa
# gobuster
# subrute
# dnsdumpster.com
# searchdns.netcraft.com
# crt.sh/?q=
# whois.arin.net
# Zscanner
# js-scan
# site:amazonaws.com inurl:target
# s3 bucket finder => digi.ninja/projects/bucket_finder.php
# awscli
# aws s3 ls s3://TARGET
# aws s3 mv FILE s3://TARGET
# site:"github.com"+TARGET+SEARCH
# gitrob, git-all-secrets, trufflehog
# site:TARGET intext:"index of /"

# remove duplicates from subdomains and urls

#-----------------------------
# usefull code
#-----------------------------
# for ipa in 98.13{6..9}.{0..255}.{0..255};do
# wget -t 1 -T 5 http://${ipa}/FUZZ;done &


# start the script here
getsubdomains
dnsscan
spoofcheck
while read sub; do
  niktoscan $sub $2
  dowfuzz $sub
done <"./$dir/$domain-domains.txt"
# if [[ $bburp == "true" ]]
# then
# burpstartup $1 $2
# burprecon $1 $2
# fi
}

main() {
if (curl -k -X HEAD $curlflag -i -s $domain 2>/dev/null 1>/dev/null) then
	echo "Connected to $domain"
	mdir "$domain"
	mdir "$domain/$startdate"
  mdir "$domain/$startdate/nikto"
  mdir "$domain/$startdate/wfuzz"
	dir="$domain/$startdate"
	recon $domain $port
else
	echo "cannot connect to $domain"
fi
}

main $domain
