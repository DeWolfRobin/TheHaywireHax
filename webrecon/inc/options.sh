while getopts ":fbdh:" o; do
    case "${o}" in
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
          "${OPTARG}"
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
