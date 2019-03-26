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
  cat "$dir/wfuzz/$1.html" | grep ">http.*</a>" -o | sed -e 's/....$//' -e 's/^.//' | sort | uniq > "$dir/urls/$1.txt"
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
  # kill $pid OR curl "http://localhost:8090/burp/stop"
} #Works

burprecon() {
  i=0
  while [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 "http://localhost:8090/v2/api-docs") = 000 ]
  do
    echo -e -n "Waiting for burp ($i s)\r"
    sleep 1
    i=$(($i+1))
  done
  echo "\nDone"
  i=0
  echo "Adding $urlscheme://$1 to the scope"
  curl -X PUT "http://localhost:8090/burp/target/scope?url=$urlscheme://$1"
  echo "Adding $urlscheme://$1 to spider"
  http POST "http://localhost:8090/burp/spider?baseUrl=$urlscheme://$1" 1>/dev/null
  while [ `http "http://localhost:8090/burp/spider/status" | jq -r ".spiderPercentage"` != 100 ]
  do
    echo -e -n "Waiting for burp spider to finish ($i s)\r"
    sleep 1
    i=$(($i+1))
  done
  http POST "http://localhost:8090/burp/scanner/scans/active?baseUrl=$urlscheme://$1" 1>/dev/null
  i=0
  while [ `http "http://localhost:8090/burp/scanner/status" | jq -r ".scanPercentage"` != 100 ]
  do
    echo -e -n "Waiting for burp spider to finish ($i s)\r"
    sleep 1
    i=$(($i+1))
  done
  echo "Burp scan done"
  curl "http://localhost:8090/burp/scanner/issues" > "$dir/burpissues.txt"
  curl "http://localhost:8090/burp/report" > "$dir/burpreport.html"
} #To be implemented

# script
usage() {
echo -e "Usage:\n\t$0 [-d] <domain>\n\nOptions:\n\t-b\t\t Disable burpsuite scan" 1>&2; exit 1;
}
