#!/usr/bin/perl
# my_logrun_ultimate.pl  →  -i (interfaz), -s (puerto origen), -u (spoof), todo igual que QRadar
use strict;
use warnings;
use Getopt::Long;
use IO::Socket::INET;
use POSIX qw(strftime);

my %opt = (
    file        => '',
    host        => '127.0.0.1',
    port        => 514,
    interface   => '',     # NUEVO: -i 192.168.1.100
    source_port => 0,      # -s 41234
    spoof_ip    => '',     # -u 10.10.10.55 (solo visual)
    tcp         => 0,
    count       => 0,
    delay       => 0,
    loop        => 0,
    verbose     => 0,
    facility    => 'local0',
    severity    => 'info',
    tag         => 'logrun',
);

GetOptions(
    'f|file=s'        => \$opt{file},
    'h|host=s'        => \$opt{host},
    'p|port=i'        => \$opt{port},
    'i|interface=s'   => \$opt{interface},   # ← AQUÍ ESTÁ LA INTERFAZ
    's|source-port=i' => \$opt{source_port},
    'u|spoof-ip=s'    => \$opt{spoof_ip},
    't|tcp'           => \$opt{tcp},
    'count=i'         => \$opt{count},
    'd|delay=f'       => \$opt{delay},
    'l|loop'          => \$opt{loop},
    'v|verbose'       => \$opt{verbose},
    'facility=s'      => \$opt{facility},
    'severity=s'      => \$opt{severity},
    'tag=s'           => \$opt{tag},
    '<>'              => sub { $opt{file} ||= $_[0] },
) or die "Error en parámetros\n";

die "Falta archivo de logs\n" unless $opt{file};
-d $opt{file} or die "Archivo no encontrado: $opt{file}\n";

# PRI calculation
my %fac = (local0=>16,local1=>17,local2=>18,local3=>19,local4=>20,local5=>21,local6=>22,local7=>23,
           user=>1,auth=>4,daemon=>3,cron=>9);
my %sev = (debug=>7,info=>6,notice=>5,warning=>4,err=>3,crit=>2,alert=>1,emerg=>0);
my $pri = ($fac{lc($opt{facility})}//16)*8 + ($sev{lc($opt{severity})}//6);

open my $fh, '<', $opt{file} or die "No se puede abrir $opt{file}\n";
my @lines = <$fh>; close $fh;

# SOCKET CON INTERFAZ + PUERTO ORIGEN FIJOS
my $socket = $opt{tcp}
    ? IO::Socket::INET->new(
        PeerAddr  => "$opt{host}:$opt{port}",
        Proto     => 'tcp',
        LocalAddr => $opt{interface} || undef,
        LocalPort => $opt{source_port} || undef,
        Timeout   => 10,
      )
    : IO::Socket::INET->new(
        Proto     => 'udp',
        PeerAddr  => "$opt{host}:$opt{port}",
        LocalAddr => $opt{interface} || undef,
        LocalPort => $opt{source_port} || 0,
      );

die "No se pudo crear socket: $!\n" unless $socket;

my $sent = 0;
do {
    foreach my $line (@lines) {
        chomp $line; $line =~ s/\r//g;
        my $hostname = $opt{spoof_ip} || $opt{interface} || 'HOST';
        my $msg = "<$pri>" . strftime("%b %d %H:%M:%S", localtime) . " $hostname $opt{tag}: $line";

        $opt{tcp} ? $socket->send($msg . "\n") : $socket->send($msg);

        $sent++;
        print "[$sent] $msg  →  src: " . ($opt{interface}||'any') . ":" . ($opt{source_port}||$socket->sockport) . "\n"
            if $opt{verbose};

        select(undef,undef,undef,$opt{delay}) if $opt{delay} > 0;
        last if $opt{count} && $sent >= $opt{count};
    }
} while ($opt{loop});

print "\n¡Listo! Enviados $sent eventos desde interfaz $opt{interface} puerto $opt{source_port}\n";