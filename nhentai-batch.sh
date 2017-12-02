#!/bin/bash

#setting  off:0  on:1
zad=1			#Auto zip the directory after downloading
dsaz=1			#Delete sourse directory after zipping

dldir="comics"	#The name of the directory you want to download to (can be ausolute or relative)



#function
function show_usage {
	echo "Usage: Add an [OPTION] when you run this script."
	echo " -a    Download from an nhentai (search/tags/artists/...) website that include multi comics. Such as https://nhentai.net/search/?q=xxxxxx ."
	echo " -b    Download from nhentai websites like https://nhentai.net/g/xxxxxx/"
	exit
}

function input_and_check_website {
	read iweb
	wget --spider "$iweb" 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "The website you inputed is invalid. Please try again:"
		input_and_check_website
	fi
}

function choosemode {
read option
case $option in
1)
echo "Please input the ordinal(s) you want to download. (separated by spaces)"
read doption
mode=1
;;
2)
echo "Please input the ordinal(s) you DON'T want to download. (separated by spaces)"
read doption
mode=2
;;
3)
mode=3
;;
*)
echo -e "Invalid input. Please try again: \c"
choosemode
;;
esac
}

function download_comic { # i name num dweb
	echo "Start downloading "$1
	echo "Name: "$2
	echo "Page Count: "$3
	if [ ! -d "$2" ]; then
		mkdir "$2"
	fi
	chmod 777 "$2"
	cd "$2"
	exn=".jpg"
	if [ -f .dl ]; then
		rm -f `cat .dl`
	fi
	for((k=1;k<=num;k++));
	do
		if [ -f $k$exn ]; then
			echo "$k$exn is existed."
			continue
		fi
		echo $k$exn > .dl
		dfile=$4$k$exn
		wget $dfile 2> /dev/null
		rm -f .dl
		if [ ! -f $k$exn ]; then
			if [ "$exn" = ".jpg" ]; then
				exn=".png"
			elif [ "$exn" = ".png" ]; then
				exn=".gif"
			else
				exn=".jpg"
			fi
			((k--))
		else
			echo -e "Download Successed \c"
			printf "%2d/%2d" $k $num
			echo ": $dfile"
		fi
	done
	cd "$ndir"
	echo "Download $1 Completed!"
	if [ $zad -eq 1 ]; then
		zipcmd="-r"
		if [ $dsaz -eq 1 ]; then
			zipcmd="-rm"
		fi
		zip $zipcmd "${2}.zip" "$2" >/dev/null
		chmod 777 "${2}.zip"
		echo "Zip $1 Completed!"
	fi
	echo
}

function download_comics_from_search {
	echo "Please input an nhentai (search/tags/artists/...) website that include multi comics."
    echo "Such as https://nhentai.net/search/?q=xxxxxx ."
	input_and_check_website
	echo
	#href list
	curl -s $iweb | grep 'class=\"caption\"' | sed 's/.*href=\"\(.*\)\" class=\"cover.*/https:\/\/nhentai.net\1/g' > ${ft[0]}
	allcnt=`sed -n '$=' ${ft[0]}`
	alli=0
	printf "Analysing... %2d/%2d" $alli $allcnt
	IFSOLD=$IFS
	IFS=$'\n'
	for web in `cat ${ft[0]}`
	do
		((alli++))
		printf "\b\b\b\b\b%2d/%2d" $alli $allcnt
		curl -s $web | grep ".*<h2>\(.*\)<\/h2>.*" | sed 's/.*<h2>\(.*\)<\/h2>.*/\1/g' | sed '2d' | sed 's/\// /g' | sed 's/\&amp;/\&/g' | sed "s/&#39;/'/g" >> ${ft[1]}
		temp=`curl -s $web"1/"`
		echo $temp | grep "https://i.nhentai.net/galleries/\d*" | sed 's/.*src="\(.*\)1\..*\".*/\1/g' >> ${ft[2]}
		echo $temp | grep "num-pages" | sed '2d' | sed 's/.*>\([0-9]\{1,\}\)<\/span><\/button>.*/\1/g' >> ${ft[3]}
	done
	IFS=$IFSOLD
	echo
	echo
	cat -n ${ft[1]}
	echo
	echo "Please select a download mode:"
	echo
	echo "1. White list mode : Download which you appoint"
	echo "2. Black list mode : Which you appoint WON'T be downloaded"
	echo "3. God mode        : DOWNLOAD ALL !!!"
	echo
	echo -e "Please input: \c"
	choosemode
	#start download
	for((i=1;i<=allcnt;i++));
	do
		#judge
		dljudge=1
		if [ $mode -eq 1 ]; then
			dljudge=0
			for j in $doption
			do
				if [ $i -eq $j ]; then
					dljudge=1
				fi
			done
		elif [ $mode -eq 2 ]; then
			for j in $doption
			do
				if [ $i -eq $j ]; then
					dljudge=0
				fi
			done
		fi
		if [ $dljudge -eq 0 ]; then
			continue
		fi
		#info
		name=`sed -n ${i}p ${ft[1]} | sed 's/[\/\\\:\*\?\"\<\>\|]//g'`
		dweb=`sed -n ${i}p ${ft[2]} | sed 's/\(https:\/\/i.nhentai.net\/galleries\/[0-9][0-9]*\/\).*/\1/g'`
		num=`sed -n ${i}p ${ft[3]}`
		
		if [ -f "${name}.zip" ]; then
			echo "Comic $i has been downloaded."
			continue
		fi
		echo
		
		#download
		download_comic $i "$name" $num "$dweb"
	done
}

function download_comics_form_multi_websites {
	echo "Please input nhentai comic website like https://nhentai.net/g/xxxxxx/ and press Enter."
    echo "Then you can input another one and press Enter again... An empty line mean end of your input."
	while true
	do
		read webs
		if [ "$webs" = "" ]; then
			break
		fi
		echo $webs >> ${ft[0]}
	done
	i=1
	for web in $(cat ${ft[0]})
	do
		name=`curl -s $web | grep ".*<h2>\(.*\)<\/h2>.*" | sed 's/.*<h2>\(.*\)<\/h2>.*/\1/g' | sed '2d' | sed 's/\// /g' | sed 's/\&amp;/\&/g' | sed "s/&#39;/'/g"`
		temp=`curl -s $web"1/"`
		dweb=`echo $temp | grep "https://i.nhentai.net/galleries/\d*" | sed 's/.*src="\(.*\)1\..*\".*/\1/g'`
		num=`echo $temp | grep "num-pages" | sed '2d' | sed 's/.*>\([0-9]\{1,\}\)<\/span><\/button>.*/\1/g'`
		download_comic $i "$name" $num "$dweb"
		((i++))
	done
}



if [ $# -eq 0 ];then
	show_usage
else
	if [ "$1" != "-a" -a "$1" != "-b" ]; then
		show_usage
	fi
fi

echo
echo "################################################################"
echo "# nhentai One key downloader                                   #"
echo "# Author: Jindai Kirin                                         #"
echo "# Github: https://github.com/YKilin/nhentai-one-key-downloader #"
echo "# Blog  : https://lolico.moe                                   #"
echo "################################################################"
echo

#check
if [ -f "$dldir" ]; then
	echo "A file named ${dldir} is existed. Please change the file name or the setting of your directory name."
	exit
fi
if [ ! -d "$dldir" ]; then
	mkdir "$dldir"
fi
chmod 777 "$dldir"
cd $dldir
ndir=`pwd`

#temp file
rdid=$RANDOM
ftd="${ndir}/.nhentai-temp-$rdid"
ft=("${ftd}/allweb" "${ftd}/name" "${ftd}/dweb" "${ftd}/num")
if [ ! -d "$ftd" ]; then
	mkdir "$ftd"
fi
chmod 777 "$ftd"
      
#start
if [ "$1" = "-a" ]; then
	download_comics_from_search
elif [ "$1" = "-b" ]; then
	download_comics_form_multi_websites
fi

echo "Download all completed! Bye~"

#delete temp file
rm -rf $ftd
