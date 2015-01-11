#!/bin/ksh
#
# metafree - Adrian Ball (ade@majords.co.uk)- 2007/01
#
# Finds all devices containing soft partitions and shows
# size/allocation, unallocated space, devices etc
#
# NB: This is not the script that is listed on Sun's BigAdmin site
#     I had written this before knowing of that one's existence, but
#     subsequently found all the links to that one to be broken, so
#     I have not seen it.
#     Strangely I had picked the same name for the script...
#     Maybe someone will find this one useful.

if [[ ! -x /usr/sbin/metastat ]] ; then
    echo "Can't run metastat binary, bogus..."
    exit 1
fi

printf "%-20s %9s %9s %10s %10s  %s\n" Device GB Used Available Capacity "Soft Partitions"

for c in $(metastat -p | nawk '$2=="-p" {print $3}' | sort -u) ; do
    if [[ ${c%%[0-9]*} == d ]] ; then
	### It's a metadevice, use metastat to find the size
	cap=$(metastat $c 2>/dev/null| nawk '/Size:/ {print $2/2048/1024;exit}')
    elif [[ ${c#/} != $c ]] ; then
	### It's a real device, work out size assuming full disk/LUN is used
	cap=$(prtvtoc $c | nawk '
	    /bytes\/sector/  {bs=$2}
	    /sectors\/cyl/   {sc=$2}
	    /accessible cyl/ {as=$2}
	    END 	     {print bs*sc*as/1024^3}')
    else 
	### Assume we have a cXtX form of device, use prtvtoc to work out
	### the size of the slice
	cap=$(prtvtoc /dev/rdsk/$c | nawk -v c=$c '
	    BEGIN {split(c,a,"s");s=a[2]}
	    /bytes\/sector/  {bs=$2}
	    $1==s {print $5*bs/1024^3}')

    fi
    used=$(metastat -p | nawk -v c=$c '
	$2=="-p" && $3==c {split($0,a,"-o") 
			   for (frag in a) { split(a[frag],sz,"-b"); used+=sz[2] } }	
	END		  { print used/2048/1024 }
    ')
    echo $cap $used | nawk '{print $1-$2, $2/$1*100}' | read avail pct
    devs=$(metastat -p | sort | nawk -v c=$c '$3==c && $2="-p" {printf "%s ", $1}')
    printf "%-20s %9.2f %9.2f %10.2f %9.1f%1s  %s\n" $c $cap $used $avail $pct % "$devs"
done	
