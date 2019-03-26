
eyewithness () {
  echo "blank"
} #To be implemented

screenshot(){
    echo "taking a screenshot of $line"
    python ~/tools/webscreenshot/webscreenshot.py -o ./$domain/$foldername/screenshots/ -i ./$domain/$foldername/responsive-$(date +"%Y-%m-%d").txt --timeout=10 -m
} #To be implemented


second-order() {
  ../submodules/second-order/second-order -base $1 -output "$dir/SO/$1" -config "../submodules/second-order/config.json"
} #To be implented


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
