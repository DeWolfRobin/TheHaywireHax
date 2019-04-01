#!/bin/bash

# Config
. inc/conf.sh

. inc/functions.sh

. inc/options.sh

recon() {
  echo ""
  # Recon-ng
  # Aquatone
# waybackurls.py => mhmdiaa
# waybackrobots.py => mhmdiaa
# gobuster
# subrute
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
tor 1>/dev/null
burpstartup
getsubdomains
dnsscan
# spoofcheck # errors due to specific lib
while read sub; do
  niktoscan $sub $2
  # dowfuzz $sub
  # second-order "$urlscheme://$sub"
  # crawlsub $sub
  # if [[ $bburp == "true" ]]
  # then
  # burprecon $sub
  # fi
done <"./$dir/$domain-domains.txt"
}

main() {
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
  echo `notify -i "$domain: Scan done" -t "saved in $dir"`
  curl "http://localhost:8090/burp/stop"
}

main $domain
