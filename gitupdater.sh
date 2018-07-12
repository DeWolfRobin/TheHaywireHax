#sh bash
echo "Searching for all git repos"
FIREDPATH="$(pwd)"
find / | grep "/.git$" > list
while read p; do
	cd $p/..
	git pull
done <list
rm ${FIREDPATH}/list
