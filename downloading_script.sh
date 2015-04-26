#!/bin/bash
print_style () {
	for (( i = 0; i < 20; i++ )); do
		printf "."
		sleep 0.1
	done
	echo ""
}

check_category () {
	if [[ "$1" -eq 0 ]] >/dev/null 2>/dev/null ; then
		echo "1"
		return
	fi
	numbers=`cat "$2" | egrep -o "^[0-9]+"`
	echo "$numbers" | egrep "^$1$" > /dev/null 2>/dev/null
	if [[ "$?" -eq 0 ]]; then
		echo "1"
		return
	fi
	echo "0"
}

home_page='.93c4f9293f239af6fe3db5c0d933c91e.html'
complete_list='.c6c15056705a75f9fd8fa006aa9435e8'
readable='.500f1c435067a26384c6b38f464da461'
current='.43b5c9175984c071f30b873fdce0a000'
temp='.3d801aa532c1cec3ee82d87a99fdf63f.html'
test1='.5a105e8b9d40e1329780d62ea2265d8a.html'
test2='.ad0234829205b9033196ba818f7a872b.html'

echo -ne "\033]0;Download wallpapers from best-wallpaper.net\007"
printf "\033c"

web='http://www.best-wallpaper.net'

man wget >/dev/null 2>/dev/null
if [[ "$?" -ne 0 ]]; then
	echo 'Command wget not found, first install wget to proceed...'
	exit 0
fi

echo 'Retrieving all the categories from the website, please be patient..!!'

print_style
wget -O "$home_page" "$web"
>$complete_list
for i in `cat $home_page | grep 'class="item_left"'  |  egrep -o "href=\"[^\"]+" | cut -d "\"" -f2 | egrep "^\/" | egrep -v "\/[0-9]+x[0-9]"`
do
	wget -O "$temp" $web$i ; pages=`cat $temp | grep -A 1 '<div class="pg_pointer">' | sed "s/href/\n/g" | tail -2 | head -1 | egrep -o ">[0-9]+<" | egrep -o "[0-9]+"`; echo "$i=$pages" >> $complete_list
done

cat $complete_list > $current

count=1
printf "\033cEnter the number of the category that you want to download. (enter 0 for downloading all the categories)\n"
for i in `cat $complete_list`
do
	printf "$count.->"
	echo $i | cut -d "_" -f1 | sed "s/\///g"
	count=$(($count+1))
done > $readable
cat $readable
flag=0

read category
flag=`check_category $category $readable`
while [[ "$flag" -eq 0 ]]; do
	echo "Input correct value."
	read category
	flag=`check_category $category $readable`
done

if [[ "$category" -eq 0 ]]; then
	echo "Downloading all the categories may take long time beacuse of large number of wallpapers, do you want to proceed (y/n)"
	read decision
	content='All'
	flag=0
	if [[ "$decision" == "y" || "$decision" == "Y"  ]]; then
		flag=1
	fi
fi

if [[ "$flag" -eq 0 ]]; then
	echo "Exiting the script"
	exit 0
fi

if [[ "$category" -ne 0 ]]; then
	content=`cat $readable | egrep "^$category\." | cut -d ">" -f2`
	awk "NR==$category" $complete_list | grep "$content" > "$current"
fi

echo "Final wallpapers will be downloaded in the folder $content.."

for (( i = 1; i < 4; i++ )); do
	echo $i.
	sleep 1
done

notify-send "Downloading started for $content"

for id in `cat $current`
do
	printf "\033c"
	name_to_be_displayed=`echo $id | cut -d "_" -f 1 | sed "s/\///g"`
	total_pages_to_be_dispalyed=`echo $id | cut -d "=" -f2`
	echo -ne "\033]0;$name_to_be_displayed, Total pages=$total_pages_to_be_dispalyed\007"
	current_dir=`pwd`
	directory=`echo $id | cut -d "_" -f1 | sed "s/\///g"`
	address=`echo $id | cut -d "=" -f1 | sed -e "s/\.html/\/page\//g"`
	address="$web""$address"
	pages=`echo $id | cut -d "=" -f2`
	mkdir -p $directory
	cd $directory

	page=1
	ls list > /dev/null 2>/dev/null

	if [[ "$?" -eq 0 ]]; then
		page=`cat list | tail -1 | egrep -o "[0-9]*$"`
	fi
	
	if [[ "$flag" -eq 1 ]]; then
		echo $pages > total.log
	fi

	flag=0
	for i in `seq $page $pages`
	do
		printf "\033cPage number $i"
		echo $i > page.log
		wget -O "$temp" "$address""$i"
		for j in `cat "$temp" | grep '<div class="pic_list_img">' | grep -o "href=\"[^\"]*" | cut -d "\"" -f2`
		do
			wget -O "$test1" "$web""$j"
			new=`cat "$test1" | grep -A 1 "16:9" | grep 'target="_blank"' | sed "s/href/\n/g" | tail -1  | cut -d "\"" -f2`
			wget --referer "$web""$j" -U "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0" -O "$test2"  "$web""$new"
			final=`cat "$test2"  | grep '<img src="/wallpaper/' | cut -d "\"" -f2`
			name=`echo $final | rev | cut -d "/" -f1 | rev`
			wget --referer "$web""$new" -U "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0" -O $name "$web""$final"
			echo "$name $i" >> list
			flag=1
		done

	done
	notify-send "Downloading finished for $content"
	cd $current_dir
done
exit 0
