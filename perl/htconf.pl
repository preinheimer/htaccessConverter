<Directory /home/khundeck/htcrawler >
</Directory>
<Directory /home/khundeck/htcrawler/0.a >
</Directory>
<Directory /home/khundeck/htcrawler/0.c >
</Directory>
<Directory /home/khundeck/htcrawler/0.b >
</Directory>
<Directory /home/khundeck/htcrawler/0.a/1.a >
</Directory>
<Directory /home/khundeck/htcrawler/0.c/1.g >
</Directory>
<Directory /home/khundeck/htcrawler/0.b/1.d >
</Directory>
<Directory /home/khundeck/htcrawler/0.a/1.a/2.a >
</Directory>
<Directory /home/khundeck/htcrawler/0.b/1.d/2.b >
	##Comment line!
	##

	####WARNING! RedirectBase' does't convert correctly. Check manually!
	RedirectBase blalbh
	SomethingElse

	####WARNING! Apache params not supported. ;-)
	ApacheParam3 doo

	####WARNING! RedirectBase' does't convert correctly. Check manually!
	RedirectBase Again!
</Directory>
<Directory /home/khundeck/htcrawler/0.a/1.a/2.a/3.a >

	####WARNING! Apache params not supported. ;-)
	ApacheParam 1

	####WARNING! Apache params not supported. ;-)
	ApacheParam 2
</Directory>

######################################################
#Total Warnings: 5 
#%ErrorTypeFound = (
#                    'RedirectBase' => 2,
#                    'OtherParamLabel' => 3
#                  );
######################################################

######################################################
## Total Files processed: 10
######################################################

## Please test before going live, no guarantees! 
