# scrib-dl
scrib-dl is a ruby script that downloads the free docs from scribd which consist from images. The script creates a folder with the name of the doc and downloading the images inside the document.

~$ ruby scrib-dl URL

#OPTIONS

+ -a File  ----  File containing URLs to download.

#EXAMPLE WITHOUT PARAMETER

~$ ruby scrib-dl http://www.scribd.com/doc/154732310/2-Donaldo-Schuller


#EXAMPLE WITH PARAMETER

-Relative  

~$ ruby scrib-dl -a ./links.txt

~$ ruby scrib-dl -a ../links.txt

~$ ruby scrib-dl -a ../../ ..  /../links.txt

-Absolute

$ ruby scrib-dl -a /\<fullpath\>/links.txt




 
