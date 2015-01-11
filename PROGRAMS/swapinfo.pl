#!/usr/bin/perl
#
# swapinfo	Print Virtual Memory statistics (swap). Solaris 9+.
#
# Prints swap usage details for RAM and disk based swap. This can be run 
#  as any user as it uses the Perl Kstat library and "swap -l".
#
# 28-Nov-2004	ver 0.61	(UNDER CONSTRUCTION, check for newer versions)
#
#
# USAGE: swapinfo [ -h ]
#        swapinfo 		# print stats
#	 swapinfo -h		# print help
#
# This program appears to pause for a second while calculating values - 
#  this is necessary as some of the variables used are counters that are
#  incremented every second.
#
# FIELDS:
#		RAM Total	Total RAM installed
#		RAM Unusable	RAM consumed by the OBP and TSBs
#		RAM Kernel	Kernel resident in RAM (and usually locked)
#		RAM Locked	Locked memory pages from swap (Anon)
#		RAM Used	Anon, Exec + Libs, Page cache
#		RAM Avail	Free memory that can be immediately used
#		Disk Total	Total disk swap configured
#		Disk Alloc	Disk swap allocated (used by pageouts)
#		Disk Free	Disk swap free
#		Swap Total	Total swap usable
#		Swap Alloc	swap allocated (used)
#		Swap Unalloc	swap reserved but not allocated
#		Swap Avail	swap available for reservation
#		Swap MinFree	swap kept free from reservations
#
# NOTE: Due to limited info from Kstat some assumptions needed to be made. 
#  Under some circumstances (swapped out kernel pages) Ram Kernel and Ram Locked
#  may not be accurate. I assume swapfs_minfree hasn't been changed from the 
#  default. This is the best I can do from Kstat alone (and without access to 
#  the Solaris source code!). For other techniques see the "SEE ALSO" section. 
#
# REFERENCE: http://www.brendangregg.com/k9toolkit.html - the swap diagram.
#
# SEE ALSO: vmstat 1 2; swap -s; echo ::memstat | mdb -k
#	    RMCmem - The MemTool Package
#	    RICHPse - The SE Toolkit
#	    "Clearing up swap space confusion" Unix Insider, Adrian Cockcroft 
#	    "Solaris Internals", Jim Mauro, Richard McDougall
#	    /usr/include/vm/anon.h, /usr/include/sys/systm.h
#
# COPYRIGHT: Copyright (c) 2004 Brendan Gregg.
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
# 08-Aug-2004	Brendan Gregg	Created this.
# 15-Aug-2004	   "	  "	Included a "swap -l" for more accurate values.


use Sun::Solaris::Kstat;
my $Kstat = Sun::Solaris::Kstat->new();


#
# --- Process command line args ---
#
if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") { &usage(); }
$DEBUG = 0;
$DEBUG = 1 if $ARGV[0] eq "-d";


#
# --- Fetch Hardware info ---
#

### pagesize
$ENV{PATH} = "/usr/bin";
chomp($PAGESIZE = `pagesize`);
$PAGETOMB = $PAGESIZE / (1024 * 1024);
$BLOCKTOP = 512 / $PAGESIZE;

### RAM total
$ram_total = 0;
foreach $i (keys(%{$Kstat->{lgrp}})) {				# instance
	foreach $c (keys(%{$Kstat->{lgrp}->{$i}})) {		# class
		$ram_total += $Kstat->{lgrp}->{$i}->{$c}->{"pages installed"};
	}
}

### RAM available for the OS
$physmem = $Kstat->{unix}->{0}->{system_pages}->{physmem};
$pagestotal = $Kstat->{unix}->{0}->{system_pages}->{pagestotal};


#
# --- Fetch VM info ---
#
foreach $count (0..12) {
	#
	#  The values are counters that increment each second, here we
	#  check them several times and look for the value changing.
	#  (reading them once then again a second later was not reliable).
	#
	foreach $var ("swap_resv","swap_avail","swap_alloc","swap_free",
	 "freemem") {
		$VMnow{$var} = $Kstat->{unix}->{0}->{vminfo}->{$var};
		unless ($count) {
			$VMold{$var} = $VMnow{$var};
			next;
		}
		if (($VMnow{$var} != $VMold{$var}) && (! $VMinfo{$var})) {
			$VMinfo{$var} = $VMnow{$var} - $VMold{$var};
		}
	}
	select(undef, undef, undef, 0.1);
	$Kstat->update();
}
$freemem = $Kstat->{unix}->{0}->{system_pages}->{freemem};
$availrmem = $Kstat->{unix}->{0}->{system_pages}->{availrmem};
$pageslocked = $Kstat->{unix}->{0}->{system_pages}->{pageslocked};
$pp_kernel = $Kstat->{unix}->{0}->{system_pages}->{pp_kernel};

#
# --- Fetch Disk Swap ---
#
($disk_total,$disk_free) = &SwapList();


#
# --- Calculations ---
#

### Swap
$swap_resv = $VMinfo{swap_resv};
$swap_free = $VMinfo{swap_free};
$swap_avail = $VMinfo{swap_avail};
$swap_alloc = $VMinfo{swap_alloc};
$swap_unalloc = $swap_free - $swap_avail;
$swap_total = $swap_resv + $swap_avail;
# assume this hasn't been tuned,
$swapfs_minfree = int($physmem / 8);

### RAM
$ram_unusable = $ram_total - $pagestotal;
if ($pp_kernel < $pageslocked) {
	# here we assume all pp_kernel pages are in memory,
	$ram_kernel = $pp_kernel;
	$ram_locked = $pageslocked - $pp_kernel;
} else {
	# here we assume pageslocked is entirerly kernel,
	$ram_kernel = $pageslocked;
	$ram_locked = 0;
}
$ram_used = $pagestotal - $freemem - $ram_kernel - $ram_locked;

### Disk
# "swap -l" technique,
$disk_alloc = $disk_total - $disk_free;
# Kstat only technique (inaccurate, and only printed in debug mode),
$disk_totalb = $swap_total - $availrmem - $ram_locked + $swapfs_minfree;
$disk_avail = $swap_avail + $swapfs_minfree - $freemem;  # assumptions here for
$disk_avail = $disk_totalb if $disk_avail > $disk_total; #  swapfs_minfree usage
$disk_resv = $disk_totalb - $disk_avail;


### format values
@Values = qw(disk_total disk_free disk_alloc disk_totalb disk_avail disk_resv
 freemem availrmem physmem pagestotal pageslocked pp_kernel ram_total 
 ram_kernel ram_used ram_unusable ram_locked swap_unalloc swap_total 
 swap_resv swap_avail swap_alloc swap_free swapfs_minfree);
foreach $var (@Values) {
	# nothing to see here, move along, move along, ...
	${"${var}_Mb"} = sprintf("%7.1f Mb",$$var * $PAGETOMB);
}


# 
# --- Print Debug ---
#
if ($DEBUG) {
	print <<END;
DEBUG      swap_free $swap_free_Mb \t$swap_free
DEBUG      swap_resv $swap_resv_Mb \t$swap_resv
DEBUG     swap_avail $swap_avail_Mb \t$swap_avail
DEBUG     swap_alloc $swap_alloc_Mb \t$swap_alloc
DEBUG   swap_unalloc $swap_unalloc_Mb \t$swap_unalloc
DEBUG        freemem $freemem_Mb \t$freemem
DEBUG      availrmem $availrmem_Mb \t$availrmem
DEBUG      pp_kernel $pp_kernel_Mb \t$pp_kernel
DEBUG    pageslocked $pageslocked_Mb \t$pageslocked
DEBUG     pagestotal $pagestotal_Mb \t$pagestotal
DEBUG        physmem $physmem_Mb \t$physmem
DEBUG swapfs_minfree $swapfs_minfree_Mb \t$swapfs_minfree
DEBUG    disk_totalb $disk_totalb_Mb \t$disk_totalb
DEBUG      disk_resv $disk_resv_Mb \t$disk_resv
DEBUG     disk_avail $disk_avail_Mb \t$disk_avail\n
END
}
	

#
# --- Print Report ---
#
print <<END;
RAM  _____Total $ram_total_Mb
RAM    Unusable $ram_unusable_Mb
RAM      Kernel $ram_kernel_Mb
RAM      Locked $ram_locked_Mb
RAM        Used $ram_used_Mb
RAM       Avail $freemem_Mb

Disk _____Total $disk_total_Mb
Disk      Alloc $disk_alloc_Mb
Disk       Free $disk_free_Mb
 
Swap _____Total $swap_total_Mb
Swap      Alloc $swap_alloc_Mb
Swap    Unalloc $swap_unalloc_Mb
Swap      Avail $swap_avail_Mb
Swap  (MinFree) $swapfs_minfree_Mb
END


# SwapList - fetch disk based swap total and free.
#            This returns the values as pages (for consistancy elsewhere).
#
sub SwapList { 
	my $sum_total = 0;
	my $sum_free = 0;
	my ($total,$free);

	#
	#  This currently uses "swap -l" to fetch the values.
	#  I'd rather use Kstat to do this, but have not found the values
	#  I need (such as ani_free?), and limited values I had to work with
	#  were not providing consistant results. I did consider swapctl(), 
	#  but running that from Perl was problematic.. Until I know of a
	#  better way, I'll use "swap -l" for this.
	#
	@Lines = `/usr/sbin/swap -l 2> /dev/null`;
	unshift(@Lines);			# drop header
	
	foreach $line (@Lines) {
		($total,$free) = $line =~ /(\d+)\s+(\d+)$/;
		next unless $total;
		$sum_total += $total;
		$sum_free += $free;
	}

	### Return as pages
	return ($sum_total * $BLOCKTOP,$sum_free * $BLOCKTOP);
}



# usage - print usage message and exit.
#
sub usage {
	print STDERR <<END;
USAGE: $0 [ -h ]
   eg, $0 			# print stats
       $0 			# print help
END
	exit 1;
}


