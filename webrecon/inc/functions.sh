mdir() {
 mkdir "$1" 2>/dev/null 1>/dev/null
} # works

dnsscan (){
  #active
  proxychains dnsrecon -d $domain -D "dnsmap.txt" -t axfr -j "`pwd`/$dir/dnsinfo.json" 2>/dev/null
} #works

spoofcheck () {
  #active
  ../submodules/spoofcheck/spoofcheck.py $domain > "$dir/$domain-spoof.txt"
} #works

getsubdomains(){
  echo $domain >> "$dir/$domain-domains.txt"
  #passive
  python ~/tools/Sublist3r/sublist3r.py -d $domain -t 10 -v -o "./$dir/$domain-domains.txt"
  #passive
  curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $domain >> "$dir/$domain-domains.txt"
  #passive
  knockpy $domain -j
  mv *.json "./$dir/"
  echo $(cat "./$dir/$domain-domains.txt") | sed 's/ /\n/g' | sort | uniq > "./$dir/$domain-domains-sorted.txt"
}

dowfuzz() {
	# proxychains wfuzz -f "$dir/wfuzz/$1.html",html -w $wordlist -t 10 -c -L -R 5 -Z --filter "c!=404" -u "$urlscheme://$1/FUZZ"
  $proxy wfuzz -f "$dir/wfuzz/$1.html",html -w $wordlist -t 10 -c -L -R 5 -Z --filter "c!=404" -u "$urlscheme://$1/FUZZ"
  cat "$dir/wfuzz/$1.html" | grep ">http.*</a>" -o | sed -e 's/....$//' -e 's/^.//' | sort | uniq > "$dir/urls/$1.txt"
} #works

niktoscan() {
  #active
  # FEATURE => scan on all website ports (detect with nmap?)
  # PROXYCHAINS doesn't work yet
	nikto -host $1 -port $2 -Format htm -output - > "$dir/nikto/$1.html"
} #works

crawlsub() {
  while read path; do
    getparams $path
  done <"$dir/urls/$1.txt"
} #works

getparams() {
  name=`echo $1 | sed 's/\//_/g'`
  pushd ../submodules/Arjun/
  python3 ../submodules/Arjun/arjun.py -u "$1" --get -t 10 > "$dir/params/$name-params.txt"
  python3 ../submodules/Arjun/arjun.py -u "$1" --post -t 10 > "$dir/params/$name-params.txt"
  popd
} #works

burpstartup() {
  # java -Xbootclasspath/p:/lib/decoder_new.jar -jar /lib/burp-rest-api-2.0.1.jar --headless.mode=true --burp.jar=/lib/burpsuite_pro_v2.0beta.jar --project-file="$dir/$1.burp" 1>/dev/null 2>/dev/null &
  nohup java -jar /lib/burp-rest-api-2.0.1.jar --headless.mode=true --burp.jar=/opt/BurpSuitePro/burpsuite_pro.jar --project-file="$dir/$domain.burp" &
  pid=`echo $!`
} #Works


# script
usage() {
echo -e "Usage:\n\t$0 [-d] <domain>\n\nOptions:\n\t-b\t\t Disable burpsuite scan" 1>&2; exit 1;
}
