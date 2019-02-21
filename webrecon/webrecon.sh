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
  cat "$dir/wfuzz/$1.html" | grep ">http.*</a>" -o | sed -e 's/....$//' -e 's/^.//' > "$dir/urls/$1.txt"
} #works

niktoscan() {
	nikto -host $urlscheme"://"$1 -port $2 -Format html -output "$dir/nikto/$1.html"
} #works

crawlsub() {
  while read path; do
    getparams $path
  done <"$dir/urls/$1.txt"
} #works

second-order() {
  ../submodules/second-order/second-order -base $1 -output "$dir/SO/$1" -config "../submodules/second-order/config.json"
} #To be implented

getparams() {
  name=`echo $1 | sed 's/\//_/g'`
  pushd ../submodules/Arjun/
  python3 arjun.py -u "$1" --get -t 10 > "../../webrecon/$dir/params/$name-params.txt"
  python3 arjun.py -u "$1" --post -t 10 > "../../webrecon/$dir/params/$name-params.txt"
  pushd ../../webrecon
} #works

burpstartup() {
  # java -Xbootclasspath/p:/lib/decoder_new.jar -jar /lib/burp-rest-api-2.0.1.jar --headless.mode=true --burp.jar=/lib/burpsuite_pro_v2.0beta.jar --project-file="$dir/$1.burp" 1>/dev/null 2>/dev/null &
  nohup java -jar /lib/burp-rest-api-2.0.1.jar --headless.mode=true --burp.jar=/opt/BurpSuitePro/burpsuite_pro.jar --project-file="$dir/$domain.burp" &
  pid=`echo $!`
  i=0
  while [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 "http://localhost:8090/v2/api-docs") = 000 ]
  do
    echo -e -n "Waiting for burp ($i s)\r"
    sleep 1
    i=$(($i+1))
  done
  echo "\nDone"
  # kill $pid OR curl "http://localhost:8090/burp/stop"
} #Works

burprecon() {
  echo "Adding $urlscheme://$1 to the scope"
  curl -X PUT "http://localhost:8090/burp/target/scope?url=$urlscheme://$1"
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
burpstartup
getsubdomains
dnsscan
spoofcheck
while read sub; do
  echo $sub
  niktoscan $sub $2
  dowfuzz $sub
  # second-order "$urlscheme://$sub"
  crawlsub $sub
  burprecon $sub
done <"./$dir/$domain-domains.txt"
# if [[ $bburp == "true" ]]
# then
# burpstartup $1 $2
# burprecon $1 $2
# fi
}

main() {
# if (curl -L -X HEAD $curlflag -i -s $domain 2>/dev/null 1>/dev/null) then
	echo "Connected to $domain"
	mdir "$domain"
	mdir "$domain/$startdate"
  mdir "$domain/$startdate/nikto"
  mdir "$domain/$startdate/wfuzz"
  mdir "$domain/$startdate/params"
  mdir "$domain/$startdate/SO"
  mdir "$domain/$startdate/urls"
	dir="$domain/$startdate"
	recon $domain $port
  echo `notify -i "TheHaywireHax" -t "done"`
  curl "http://localhost:8090/burp/stop"
# else
# 	echo "cannot connect to $domain"
# fi
}

main $domain
