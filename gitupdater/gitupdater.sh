#sh bash
echo "Searching for all git repos"
find / | grep "/.git$" > list
while read p; do
	cd $p/..
	git pull
done <list
rm list
