#!/usr/bin/perl
#
# kstat_walk	Walk down the kstat tree. Solaris 8+.
#
# This uses the Kstat module to walk the Kstat structures either 
#  as a tree or as a list. This program is designed as a starting point
#  for writing other Perl Kstat programs (hence the verbose comments).
#
# 12-Mar-2005	ver 2.00
#
# USAGE: kstat_walk [-h] [-t [ level ] ]
#        kstat_walk   			# print grep'able output
#        kstat_walk -t			# print Kstat tree
#        kstat_walk -t 1		# print to one level only
#	 kstat_walk -h			# print help
#
# SEE ALSO: /usr/bin/kstat, /usr/include/sys/kstat.h
#
# COPYRIGHT: Copyright (c) 2004, 2005 Brendan Gregg.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#  (http://www.gnu.org/copyleft/gpl.html)
#
# Author: Brendan Gregg  [Sydney, Australia]
#
# 10-Mar-2004	Brendan Gregg	Created this.
# 12-Mar-2005	   "      "	Changed default output.

use Sun::Solaris::Kstat;
my $Kstat = Sun::Solaris::Kstat->new();

#
# --- Process command line args ---
#
if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") { &usage(); }
if ($ARGV[0] eq "-t") { 
	$TREE = 1;		# print tree style output
	$level = $ARGV[1] || 5;
} else {
	$level = 5;
	$TREE = 0;
}


#
# --- Main Loop ---
#
foreach $module (keys(%$Kstat)) {
	#
	#  Walk Level 1 - Modules
	#
	print "$module\n" if $TREE;
	next if $level < 2;
	$Modules = $Kstat->{$module};

	foreach $instance (keys(%$Modules)) {
		#
		#  Walk Level 2 - Instances
		#
		print "  $instance\n" if $TREE;
		next if $level < 3;
		$Instances = $Modules->{$instance};

		foreach $name (keys(%$Instances)) {
			#
			#  Walk Level 3 - Names
			#
			print "    $name\n" if $TREE;
			next if $level < 4;
			$Names = $Instances->{$name};

			foreach $stat (keys(%$Names)) {
				#
				#  Walk Level 4 - Statistics
				#
				$value = $$Names{$stat};
				if ($TREE) {
				   printf ("      %-24s %s\n",$stat,$value);
				} else {
				   print "$module:$instance:$name:$stat:$value\n";
				}
			}
		}
	}
}
#
# To document the above, lets look at the following output:
#
# 	$ ./kstat_walk -g | grep lbolt
# 	unix:0:system_misc:lbolt:116958483
#
# (lbolt gives an idea of how long the server has been up for). The output
# above has the structure, 
#
#	module:instance:name:statistic:value
#
# and is labelled in this program as,
#
#	$module:$instance:$name:$stat:$value
#
# The above technique iterated over each hash. The following direct method
# also works,
#
# print "lbolt: ",$Kstat->{unix}->{0}->{system_misc}->{lbolt},"\n";  



# usage - print usage message and exit.
#
sub usage {
	print STDERR <<END;
USAGE: kstat_walk [-h] [-t [ level ] ]
   eg, kstat_walk		# print grep'able output
       kstat_walk -t 		# print Kstat tree
       kstat_walk -t 1 		# print tree to 1 level
       kstat_walk | grep dnlc	# use with grep
END
	exit 1;
}



