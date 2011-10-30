<?php
// 2009 Paul Reinheimer
// http://blog.preinheimer.com/index.php?/archives/340-.htaccess-to-httpd.conf.html
// No warranties expressed or implied
// Special thanks to Rich Bowen http://drbacchus.com/

//Improvements? Let me know! Bugs? Send a patch.
//Unsupported Software lies below.

/* Example Usage:
 *    /var/www/domain.com> php htaccess.php > ~/htaccess.conf
 * Filtering to exclude (substring match)
 *    /var/www/domain.com> php htaccess.php evilDirectory > ~/htaccess.conf
 */

//Start from the present working directory, recurse from here. Using the real path avoids a bug where .htaccess files in the PWD are omitted from results on some systems
$startPath = realpath("./");
$ite= new RecursiveDirectoryIterator($startPath);

//Lets give people a hand, skip these directories. Especially helpful when run on dev systems
$filters = array(".svn", ".cvs");

//Merge base set of filters with any from the command line
if(count($argv) > 0)
{
   unset($argv[0]);
   $filters = array_merge($filters, $argv);
}

//Iterate recursively through everything from here on in, of course filtering out stuff from the filter list
foreach (new fileFilter(new RecursiveIteratorIterator($ite), $filters) as $filename=>$cur)
{
   $htaccessFiles[] = $filename;
}

//No files? Quit now!
if (count($htaccessFiles) == 0)
{
   die("No .htaccess files found");
}

//Sort the list, place least depth first. This is important to allow overrides from sub-directories to occur correctly
usort($htaccessFiles, 'sorter');

//Warnings encountered
$flags = 0;

//Iterate over found files (sorted now) and read them in.
foreach($htaccessFiles as $file)
{
   //Grab the file and print out the <Directory $path> bit
   $path = realpath(pathinfo($file, PATHINFO_DIRNAME));
   echo "<Directory $path>\n";
   $lines = file($file);
   if(count($lines) > 0)
   {
		//Tab the file in, check for RedirectBase which may cause problems
       foreach($lines as $line)
       {
           echo "\t$line";
           if(stripos($line, "RedirectBase") !== FALSE)
           {
	       //Not tabbed! See what happens there?
               echo "# WARNING The above line contains RedirectBase which may not convert directly to a conf file. Please check manually\n";
               $flags++;
           }
       }
      
       //Handle issues where files don't end with a newline
       if (in_array(substr($line, -1), array("\n", "\r")))
       {
           echo "</Directory>\n\n";
       }else
       {
           echo "\n</Directory>\n\n";
       }
   }else{
       //File was empty, leave the stub in
       echo "\n</Directory>\n\n";
   }
}

//Check for warnings
if ($flags > 0)
{
   echo "# A total of $flags warnings were encountered. Please read through the file and correct any noted problems\n";
}else
{
   echo "# No warnings detected \n";
}

echo "# Please test before going live, no guarantees! \n";




//Sort by the number of path segments, least first
function sorter($a, $b)
{
   $a = count(explode("/", $a));
   $b = count(explode("/", $b));
   if($a == $b)
   {
       return 0;
   }
   if($a > $b)
   {
       return 1;
   }
   return -1;
}



//Filter out specified files. 
class fileFilter extends FilterIterator
{
   private $filters;
   public function __construct(Iterator $iterator, $filters)
   {
       parent::__construct($iterator);
       $this->filters = $filters;
   }

   public function accept()
   {
       $dir = $this->getInnerIterator()->current();
       foreach($this->filters as $filter)
       {
           if(strpos($dir, $filter) !== false)
           {
               return false;
           }
       }
       
       if (strpos($dir, ".htaccess") !== false)
       {
           return true;
       }
       //echo "Skipping $dir\n";
       return false;
   }
}
