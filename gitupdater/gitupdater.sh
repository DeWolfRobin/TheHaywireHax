#sh bash
find / | grep "/.git$" > list
while read p; do
	cd $p/..
	git pull
done <list