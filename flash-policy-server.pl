#!/usr/bin/env perl

# Copyright (c) 2011 Yura Rodchyn
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE. 

use Socket;
use IO::Handle;
use Getopt::Long;

GetOptions(	       
    'disable-log'  => \$disable_log,
    'help|?'	   => \$help,
    'l|log_file=s' => \$log_file,
    'd|domains=s'  => \$domains,
    'v|verbose'    => \$verbose
);

if($help) {

    print "\nUsage: perl flash-policy-server.pl [options]\n\n  --disable-log    Disable logging\n  --help|-?        Show this help\n  --log_file|-l    File to write logs\n  --domains|-d     Access domains\n  --verbose|-v     Print log messages to screen\n";

} else {

my $logfile = $log_file || 'flash-policy-server.log';

if (!$disable_log) {
    open(LOG_FILE, ">$logfile") or warn "Can't open $logfile: $!\n";
    LOG_FILE->autoflush(1);
}

my $port = 843;
my $proto = getprotobyname('tcp');

&log("Starting flash policy server on port $port");

socket(Server,     PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, 1 ) or die "setsockopt: $!";
bind(Server,       sockaddr_in($port,INADDR_ANY)) or die "bind: $!";
listen(Server,     SOMAXCONN) or die "listen: $!";
Server->autoflush( 1 );

my $paddr;
&log("Server started.\nWaiting for connections.");

$/ = "\0";

for ( ; $paddr = accept(Client,Server); close Client) {
    Client->autoflush(1);
    my($port,$iaddr) = sockaddr_in($paddr);
    my $ip_address   = inet_ntoa($iaddr);
    my $name         = gethostbyaddr($iaddr,AF_INET) || $ip_address;
    &log( scalar localtime() . ": Connection from $name" );
 
    my $line = <Client>;
    &log("Input: $line");

    if ($line =~ /.*policy\-file.*/i) {
        print Client &xml;
    }
}

sub xml {
    my $str = '<cross-domain-policy>';
    @domains = split(/,/, $domains || "*");
    foreach $domain (@domains) {
       $str .= '<allow-access-from domain="' . $domain . '" to-ports="*" />';
    }
    return $str . "</cross-domain-policy>\0";
}

sub log {
    my($msg) = @_;
    if (!$disable_log) {
        print LOG_FILE $msg,"\n";
    }
    print "$msg\n" if $verbose;
}

}