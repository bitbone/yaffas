# sysinfo-lib.pl
# Pascal Gauthier (belzebuth@destination.ca)
# (c) Under GPL license

use Yaffas::UI;

do '../web-lib.pl';
&init_config();
%access = &get_module_acl();


#Read IRQ info
sub list_irq
{
local ($_, @rv, %irqlist, @irq_splitter, @device_splitter, $i);

open(PROC_INTERRUPTS, "/proc/interrupts");
while (<PROC_INTERRUPTS>) {
    if ($_ =~ /\d+:/) {
	@irq_splitter = split(/:/, $_, 2);
	@device_splitter = split(/(XT-PIC|IO-APIC-edge)/, $_, 2);
	$irq_splitter[0] =~ s/\s*(\d+)\s*/$1/;
	$irqlist{$irq_splitter[0]} = $device_splitter[2];
	#push(@rv, $irqlist);
	#%irqlist = (%irqlist
    };
};
close(PROC_INTERRUPTS);
#return @rv;
	return %irqlist;
}


#Read the ioports
sub list_ioports
{
local ($_, @rv, $io, @splitter);

open(PROC_IOPORTS, "/proc/ioports");
while (<PROC_IOPORTS>) {
    @splitter = split(/:/, $_, 2);
    $io = {'ioport'=>$splitter[0], 'device'=>$splitter[1]};
    push(@rv, $io);
};
close(PROC_IOPORTS);
return @rv;
}


#Read the loaded module
sub list_modules
{
local ($_, @rv, $lsmod, @splitter, $tmp);

open(PROC_MODULES, "/proc/modules");
while ($_ = <PROC_MODULES>) {
    ($splitter[0], $splitter[1]) = ($_ =~ /\S+/g);
    ($tmp, $splitter[2]) = split(/\)/, $_, 2);
    $lsmod = {'module_name' => $splitter[0], 'module_size' => $splitter[1], 'module_referring' => $splitter[2]};
    push(@rv, $lsmod);
};
close(PROC_MODULES);
return @rv;
}


#Read network traffic
sub net_load
{
local ($_, @rv, @nic_splitter, @netstat_splitter, $nic);

open(PROC_NETSTAT, "/proc/net/dev");
while ($_ = <PROC_NETSTAT>) {
    if ($_ =~ /\w:/) {
	@nic_splitter = split(/:/,$_,2);
	@netstat_splitter = ($nic_splitter[1] =~ /\S+/g);
	$nic = {'interface'=>$nic_splitter[0], 'r_bytes'=>$netstat_splitter[0], 'r_errors'=>$netstat_splitter[2], 'r_dropped'=>$netstat_splitter[3], 'r_frame'=>$netstat_splitter[5], 's_bytes'=>$netstat_splitter[8], 's_errors'=>$netstat_splitter[10], 's_dropped'=>$netstat_splitter[11], 's_collisions'=>$netstat_splitter[13], 's_carrier'=>$netstat_splitter[14]};
	push(@rv, $nic);
    };
};
close(PROC_NETSTAT);
return @rv;
}


#Read the active connection
sub list_connections
{
local (@rv, @cmd, @splitter, @cond_split, @unix_split, $param, $netstat, $i);

$param = $_[0];
if ($param eq "connections" || $param eq "unixsockets") {
    @cmd = `netstat`;
}
else {
    @cmd = `netstat -l`;
};
for($i=0; $i<@cmd; $i++) {
    @cond_split = split(/ /, $cmd[$i], 2);
    if ($param eq "connections" || $param eq "opensockets") {
	if ($cond_split[0] eq "tcp" || $cond_split[0] eq "upd" || $cond_split[0] eq "raw") {
	    @splitter = ($cmd[$i] =~ /\S+/g);
    	    $netstat = {'protocol'=>$splitter[0], 'recv'=>$splitter[1], 'send'=>$splitter[2], 'local'=>$splitter[3], 'foreign'=>$splitter[4], 'state'=>$splitter[5]};
    	    push(@rv, $netstat);
	};
    }
    else {
	if ($cond_split[0] eq "unix") {
	    @splitter = split(/\[ *(\S+)* \]/, $cmd[$i], 3);
	    ($netstat{'protocol'}, $netstat{'refcnt'}) = split(/\s+/, $splitter[0], 2);
	    $netstat{'flags'} = $splitter[1];
	    @unix_split = split(/\s+/, $splitter[2], 5); 
	    #print "$unix_split[1] <br>";
	    if ($unix_split[1] eq "STREAM") {
		$netstat = {'protocol'=>$netstat{'protocol'}, 'refcnt'=>$netstat{'refcnt'}, 'flags'=>$netstat{'flags'}, 'type'=>$unix_split[1], 'state'=>$unix_split[2], 'inode'=>$unix_split[3], 'path'=>$unix_split[4]};
		push(@rv, $netstat);
	    } elsif ($unix_split[1] eq "DGRAM") {
		#@unix_split = split(/\s+/, $splitter[2], 5); 
		$netstat = {'protocol'=>$netstat{'protocol'}, 'refcnt'=>$netstat{'refcnt'}, 'flags'=>$netstat{'flags'}, 'type'=>$unix_split[1], 'inode'=>$unix_split[2]};
		push(@rv, $netstat);
	    };
	};
    };
};

return @rv;
}

#Read information about users connected
sub who
{
local (@rv, @cmd, @splitter, $who, $i);

@cmd = `w`;
for($i=1; $i<@cmd; $i++) {
    @splitter = ($cmd[$i] =~ /\S+/g);
    $who = {'users'=>$splitter[0], 'tty'=>$splitter[1], 'from'=>$splitter[2], 'at'=>$splitter[3], 'idle'=>$splitter[4], 'jcpu'=>$splitter[5], 'pcpu'=>$splitter[6], 'what'=>$splitter[7]};
    push(@rv, $who);
}

return @rv;
}

#Read OS information
sub os_info
{
local ($osinfo);

open(PROC_HOSTNAME,"/proc/sys/kernel/hostname");
$osinfo{'hostname'} = <PROC_HOSTNAME>;
close(PROC_HOSTNAME);
open(PROC_DOMAINAME,"/proc/sys/kernel/domainname");
$osinfo{'domainname'} = <PROC_DOMAINAME>;
close(PROC_DOMAINAME);
open(PROC_OSTYPE,"/proc/sys/kernel/ostype");
$osinfo{'ostype'} = <PROC_OSTYPE>;
close(PROC_OSTYPE);
open(PROC_OSRELEASE,"/proc/sys/kernel/osrelease");
$osinfo{'osrelease'} = <PROC_OSRELEASE>;
close(PROC_OSRELEASE);
return $osinfo;
};


#Read the meminfo in /proc device
sub meminfo
{
local ($_, @rv, @mem_splitter, @swap_splitter, $meminfo);

open(PROC_MEMINFO, "/proc/meminfo");

if ( `uname -r` =~ /^(3\.\d|2\.6)/ ) {
    # Get it the easy way
    while ($_ = <PROC_MEMINFO>) {
        if ( /^MemTotal:\s+(\d+)\skB/ ) { $mem_total = $1 };
        if ( /^MemFree:\s+(\d+)\skB/ ) { $mem_free = $1 };
        if ( /^Buffers:\s+(\d+)\skB/ ) { $mem_buffers = $1 };
        if ( /^Cached:\s+(\d+)\skB/ ) { $mem_cached = $1 };
        if ( /^SwapCached:\s+(\d+)\skB/ ) { $mem_shared = $1 };
        if ( /^SwapTotal:\s+(\d+)\skB/ ) { $swap_total = $1 };
        if ( /^SwapFree:\s+(\d+)\skB/ ) { $swap_free = $1 };

        $meminfo = {'mem_total'=>$mem_total, 'mem_used'=>($mem_total - $mem_free), 'mem_free'=>$mem_free, 'mem_shared'=>$mem_shared, 'mem_buffers'=>$mem_buffers, 'mem_cached'=>$mem_cached, 'swap_total'=>$swap_total, 'swap_used'=>( $swap_total - $swap_free ), 'swap_free'=>$swap_free};
    }
} else {
    while ($_ = <PROC_MEMINFO>) {
        if ($_ =~ /Mem:/) {
	    @mem_splitter = ($_ =~ /\d+/g);
        }
        if ($_ =~ /Swap:/) {
    	    @swap_splitter = ($_ =~ /\d+/g);
        }
        $meminfo = {'mem_total'=>$mem_splitter[0], 'mem_used'=>$mem_splitter[1], 'mem_free'=>$mem_splitter[2], 'mem_shared'=>$mem_splitter[3], 'mem_buffers'=>$mem_splitter[4], 'mem_cached'=>$mem_splitter[5], 'swap_total'=>$swap_splitter[0], 'swap_used'=>$swap_splitter[1], 'swap_free'=>$swap_splitter[2]};
    }
}

close(PROC_MEMINFO);
return $meminfo;
};


#Read information about the CPU
sub cpu_info
{
local ($_, $cpuinfo, $cpu, @splitter);

open(PROC_CPUINFO, "/proc/cpuinfo");
while ($_ = <PROC_CPUINFO>) {
    if ($_ =~ /model name/) {
	@splitter = split(/:/, $_, 2);
	$cpu{'name_arch'} = $splitter[1];
    };
    if ($_ =~ /^processor/) {
	@splitter = split(/:/, $_, 2);
	$cpu{'smp_level'} = $splitter[1];
	$cpu{'smp_level'}++;
    };
};
$cpu{'arch'} = `arch`;
close(PROC_CPUINFO);
return $cpu;
};


#Read information about filesystem
sub fsmount
{
local ($_, $fs, @rv, @splitter);

open(PROC_MOUNT, "/proc/mounts");
while ($_ = <PROC_MOUNT>) {
    @splitter = ($_ =~ /\S+/g);
    $fs = {'device'=>$splitter[0], 'directory'=>$splitter[1], 'fstype'=>$splitter[2],'mode'=>$splitter[3]};
    push(@rv, $fs);
};
close(PROC_MOUNT);
return @rv;
};


#Read the overall load and uptime
#Based on whattime.c (procps-2.0.2)
sub loadavg_uptime
{
local ($_, @splitter);
my %load;

open(PROC_LOADAVG, "/proc/loadavg");
($load{'one'},$load{'five'},$load{'fifteen'})  = (<PROC_LOADAVG> =~ /(\d+\.\d+)/g);

# 99 percent here, because we have 4 pixels of begin and end graphic,
# the graphs aren't very precise anyway...so matters little.
if (($load{'one'}*100) > 100) {
    $load{'bar_1'} = 100;
}
else {
    $load{'bar_1'} = $load{'one'}*99;
};
if (($load{'five'}*100) > 100) {
    $load{'bar_5'} = 100;
}
else {
    $load{'bar_5'} = $load{'five'}*99;
};
if (($load{'fifteen'}*100) > 100) {
    $load{'bar_15'} = 100;
}
else {
    $load{'bar_15'} = $load{'fifteen'}*99;
};
close(PROC_LOADAVG);

open(PROC_UPTIME, "/proc/uptime");
@splitter = (<PROC_UPTIME> =~ /\S+/g);
$load{'updays'} = $splitter[0] / (60*60*24);
$load{'upminutes'} = $splitter[0] / 60;
$load{'totalhours'} = $load{'upminutes'} / 60;
$load{'uphours'} = $load{'totalhours'} % 24;
$load{'upminutes'} = $load{'upminutes'} % 60;
close(PROC_UPTIME);
return %load;
};

#Read the drive usage from df

sub disk_free
{
	my @df_lines;
	open(DF_OUTPUT, "/bin/df -hP|");
	@df_lines = <DF_OUTPUT>;

	return @df_lines;
};

# Get a list of current client connections

sub list_net_connections
{
    open (PROCNETBUFF,"< /proc/net/ip_conntrack");
    @ip_conntrack = <PROCNETBUFF>;
    close (PROCNETBUFF);

    foreach (@ip_conntrack){
        $_=~ s/\[\S+\]\s//;
        $proto=$_;

        if (/tcp/){
            $proto =~ s/(\w+)\s+(\d+)\s(\S+)\s(\w+)\ssrc=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\s+src=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\s+use=(\S+)\s*\n/$1/;
            $state     = $4;
            $srcaddr   = $5;
            $dstaddr   = $6;
            $srcport   = $7;
            $dstport   = $8;
            $plpl      = $10;

        } elsif (/udp/){
            $proto =~ s/(\w+)\s+(\d+)\s(\S+)\ssrc=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\s+src=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\s+use=(\S+)\s*\n/$1/;
            $state     = "           ";
            $srcaddr   = $4;
            $dstaddr   = $5;
            $srcport   = $6;
            $dstport   = $7;
            $plpl      = $9;
        }  
        $srcportname="";
        $dstportname="";
        if ($srcportname = getservbyport $srcport,$proto){ } else {$srcportname = "[???]";};
        if ($dstportname = getservbyport $dstport,$proto){ } else {$dstportname = "[???]";};
        if ($srcportname eq "[???]" && $dstportname eq "[???]"){$portname="[???]";}
        if ($srcportname ne "[???]" && $dstportname eq "[???]"){$portname=$srcportname;}
        if ($srcportname eq "[???]" && $dstportname ne "[???]"){$portname=$dstportname;}
        if ($srcportname ne "[???]" && $dstportname ne "[???]"){$portname=$srcportname."-".$dstportname."\t";}
    }
};

# Simple HTML bar graph generator.
# Accepts either 1 or up to 3 percentage arguments.
sub bar_graph {
	$color{'1'}="red";
	$color{'2'}="#fff000";
	$color{'3'}="green";
	$current=1;
	my $ret;
	# Got one arg, draw one segment
	if ( $#_ == 0 ) {
		$item = pop;
		$ret .= $Cgi->div( {-style=>"height: 1em; padding:0px; margin:0px; width: $item%; background-color: $color{'2'};"});
	}
	# Two+ args, draw a segmented graph in red, yellow, and optional green.
	else {
		$ret .= $Cgi->start_table({-style=>"border-collapse: collapse; width: 100%"});
		$ret .= $Cgi->start_Tr();
		while ( @_ ) {
			$item = shift;
			$ret .= $Cgi->start_td( {-style=>"height: 1em; padding: 0px; margin: 0px; width: $item%; background-color: $color{$current}; border: 0px solid black;"});
			$ret .= "&nbsp;";
			$ret .= $Cgi->end_td();
			$current++;
		}
		$ret .= $Cgi->end_Tr();
		$ret .= $Cgi->end_table();
	}
	return $ret;
}

1;
