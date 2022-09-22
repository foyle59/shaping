#!/usr/bin/perl

use DBI;

$file = "/usr/local/system/shaper/shaper.conf.eth1";
$i = 0;
%tc = ();
$sfq = 0;
$raddb   = "radius";
$raduser = "radius";
$radpass = "xxxxxx";
$dbname = "billing";
$dbuser = "billing";
$dbpass = "xxxxxx";
$dbhost = "aaa.bbb.ccc.ddd";
$size	= 256000;
#$size	= 300000;
#$size	= 20480;
$mb     = 1048576;
@nets = (1, 2, 3, 5, 6, 7, 8, 9, 13, 16, 17, 20, 21, 24, 25, 26, 28, 29, 30, 31, 111);
%real = (248 => 0x15, 249 => 0x16, 79 => 0x18, 204 => 0x1b, 205 => 0x1c, 206 => 0x1d, 207 => 0x1e);
%corp = ();
%queue = ();

($sec,$min,$hour,$day,$month,$year, $trash) = localtime(time);
$year += 1900;
$month++;
$date = $year . "-" . $month . "-1";

$dbh   = DBI->connect("dbi:Pg:dbname=$raddb;host=$dbhost", $raduser, $radpass, {AutoCommit => 0});
#$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass, {AutoCommit => 0});
$query = "SELECT username FROM radreply WHERE attribute='Mikrotik-Rate-Limit'";
$sth   = $dbh->prepare($query);
$sth->execute();
$dbh->commit or die $dbh->errstr;
while (@row = $sth->fetchrow_array) {
  $queue{$row[0]} = 1;
}

print "tc qdisc del dev eth1 root\n";
print "tc qdisc add dev eth1 root handle 1:0 htb default ffff r2q 50\n";
print "tc class add dev eth1 parent 1:0 classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 25000\n";
#print "tc class add dev eth1 parent 1:0 classid 1:1 htb rate 500mbit ceil 1000mbit\n";
print "tc filter add dev eth1 parent 1:0 prio 10 protocol ip u32\n";
print "tc filter add dev eth1 parent 1:0 handle 10: protocol ip u32 divisor 256\n";	#0.0.0.0/0
print "tc filter add dev eth1 parent 1:0 handle 11: protocol ip u32 divisor 256\n";	#192
print "tc filter add dev eth1 parent 1:0 handle 12: protocol ip u32 divisor 256\n";	#168
print "tc filter add dev eth1 parent 1:0 handle 13: protocol ip u32 divisor 256\n";	#194
print "tc filter add dev eth1 parent 1:0 handle 14: protocol ip u32 divisor 256\n";	#8
print "tc filter add dev eth1 parent 1:0 handle 15: protocol ip u32 divisor 256\n";	#248
print "tc filter add dev eth1 parent 1:0 handle 16: protocol ip u32 divisor 256\n";	#249
print "tc filter add dev eth1 parent 1:0 handle 17: protocol ip u32 divisor 256\n";     #44
print "tc filter add dev eth1 parent 1:0 handle 18: protocol ip u32 divisor 256\n";	#79
print "tc filter add dev eth1 parent 1:0 handle 19: protocol ip u32 divisor 256\n";	#91
print "tc filter add dev eth1 parent 1:0 handle 1a: protocol ip u32 divisor 256\n";	#237
print "tc filter add dev eth1 parent 1:0 handle 1b: protocol ip u32 divisor 256\n";	#204
print "tc filter add dev eth1 parent 1:0 handle 1c: protocol ip u32 divisor 256\n";	#205
print "tc filter add dev eth1 parent 1:0 handle 1d: protocol ip u32 divisor 256\n";	#206
print "tc filter add dev eth1 parent 1:0 handle 1e: protocol ip u32 divisor 256\n";	#207

$k=0x30;
foreach $i (@nets) {
  $corp{$i} = $k;
  printf("tc filter add dev eth1 parent 1:1 handle %x: protocol ip u32 divisor 256\n", $k++);
}

print "tc filter add dev eth1 parent 1:0 protocol ip prio 10 u32 ht 800:: match ip dst 0.0.0.0/0 hashkey mask 0xff000000 at 16 link 10:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 10:c0: match ip dst 192.0.0.0/8 hashkey mask 0xff0000 at 16 link 11:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 10:c2: match ip dst 194.0.0.0/8 hashkey mask 0xff0000 at 16 link 13:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 11:a8: match ip dst 192.168.0.0/16 hashkey mask 0xff00 at 16 link 12:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 13:8: match ip dst 194.8.0.0/16 hashkey mask 0xff00 at 16 link 14:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 13:2c: match ip dst 194.44.0.0/16 hashkey mask 0xff00 at 16 link 17:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 10:5b: match ip dst 91.0.0.0/8 hashkey mask 0xff0000 at 16 link 19:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 19:ed: match ip dst 91.237.0.0/16 hashkey mask 0xff00 at 16 link 1a:\n";


$k=0x30;
foreach $i (@nets) {
  printf("tc filter add dev eth1 parent 1:0 protocol ip u32 ht 12:%x: match ip dst 192.168.%d.0/24 hashkey mask 0xff at 16 link %x:\n", $i, $i, $k++);
}

print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 14:f8: match ip dst 194.8.248.0/24 hashkey mask 0xff at 16 link 15:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 14:f9: match ip dst 194.8.249.0/24 hashkey mask 0xff at 16 link 16:\n";
print "tc filter add dev eth1 parent 1:0 protocol ip u32 ht 17:4f: match ip dst 194.44.79.0/24 hashkey mask 0xff at 16 link 18:\n";

print "tc class add dev eth1 parent 1:1 classid 1:ffff htb rate 400mbit ceil 700mbit prio 4 burst 350kb cburst 512kb quantum 20000\n";
print "tc qdisc add dev eth1 parent 1:ffff handle ffff: sfq perturb 10\n";

$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass, {AutoCommit => 0});

my $rv  = $dbh->do("SET CLIENT_ENCODING TO 'UTF8'");

open(CONF, $file) or die "Can't find conf file\n";

$string = "";
while (<CONF>) {
  next if ($_ =~ /^#/);
  chomp;
  $string = '';
  @kit = ();
  if ($_ =~ /^class/) {
    %tc = ();
    @kit = split();
    $sfq = 0;
    foreach $par (@kit) {
      ($key, $value) = split("=", $par);
      $tc{$key} = $value;
    }
   $string = "tc class add dev eth1 parent 1:$tc{'parent'} classid 1:$tc{'class'} htb rate $tc{'rate'} prio $tc{'prio'}";
   if (defined($tc{'ceil'})) {
   	$string .= " ceil $tc{'ceil'}";
   }
   if (defined($tc{'burst'})) {
	$string .= " burst $tc{'burst'}";
   }
   if (defined($tc{'cburst'})) {
     $string .= " cburst $tc{'cburst'}";
   }
   if (defined($tc{'quantum'})) {
     $string .= " quantum $tc{'quantum'}";
   }
   print $string . "\n";
   next;
  }
  if ($_ =~ /^rule/) {
    if ($sfq == 0) {
      print "tc qdisc add dev eth1 parent 1:$tc{'class'} handle $tc{'class'}: sfq perturb 10\n";
#      print "tc qdisc add dev eth1 parent 1:$tc{'class'} handle $tc{'class'}: %tc{'leaf'} perturb 10\n";
      $sfq = 1;
    }
    @kit = split();
    $string = $kit[1];
    if ($#kit > 1) {
      $string = $kit[1] . $kit[2];
    }
    print "tc filter add dev eth1 protocol ip parent 1:0 prio 10 u32 " . rule($string) . " flowid 1:$tc{'class'}\n";
    next;
  }
  if ($_ =~ /^sql/) {
    %tc = ();
    @kit = split();
    foreach $par (@kit) {
      ($key, $value) = split("=", $par);
      $tc{$key} = $value;
    }
  }
  if ($_ =~ /^req/) {
    @kit = split("=");
    $rule = request($kit[1], $tc{'sql'});
#    if ($kit[1] =~ '^Безлимитный') {
#      $rule = request2($kit[1], $tc{'sql'});
#    }
#    else {
#      $rule = request($kit[1], $tc{'sql'});
#    }
    $tc{'sql'} = $rule;
  }
}

sub request {
  local $value = $_[0];
  local $rule  = $_[1];
  local @ids   = ();
  local $i     = 0;
  local $id    = '';

  $a = "SELECT login, a.plan, ipaddr, band as band, uband, SUM(traf_snt)/$mb, SUM(traf_rcd)/$mb
        FROM client1 a, acc b, ipaddress c, plan d
        WHERE dot >= '$date' AND code=b.id AND code=c.id AND a.plan=d.name";
  if ($value =~ /\*/) {
    $value =~ s/\*/%/g;
    $a .= " AND d.name LIKE '$value'";
  }
  else {
    $a .= " AND d.name='$value'";
  }
  $q = $a . " GROUP BY login, c.ipaddr, a.plan,  band, uband";
  $sth = $dbh->prepare($q);
  $sth->execute();
  $dbh->commit or die $dbh->errstr;
  while (@row = $sth->fetchrow_array) {
    next if ($queue{$row[0]});
    if ($id ne $row[0]) {
      $rule++;
      # change bandwidth to 512 kbit in case traffic summarry more than defined limit
#      $row[3] = 512 if (($row[1] =~ /^Безлимитный/) && ($row[5] > $size));
      $class = "tc class add dev eth1 parent 1:$tc{'parent'} classid 1:$rule htb rate " . $row[3]/4 . "kbit ceil $row[3]kbit prio $tc{'prio'}";
      $class .= " burst " . $tc{'burst'} if (defined($tc{'burst'}));
      $class .= " cburst " . $tc{'cburst'} if (defined($tc{'cburst'}));
      $class .= " quantum " . $tc{'quantum'} if (defined($tc{'quantum'}));
      print $class . "\n";
      #print "tc qdisc add dev eth1 parent 1:$rule handle $rule: sfq perturb 10\n";
      print "tc qdisc add dev eth1 parent 1:$rule handle $rule: pfifo limit 50\n";
    }
    @ip = split(/\./, $row[2]);
#    $filter = "tc filter add dev eth1 protocol ip parent 1:0 prio 10 u32 ";
#    $filter = sprintf("%s ht %x:%x: ", $filter, $corp{$ip[2]}, $ip[3]) if ($ip[0] eq 192 && $ip[1] eq 168);
#    $filter = sprintf("%s ht 2:%x: ", $filter, $ip[3]);
#    $filter .= "match ip dst $row[2] flowid 1:$rule\n";
#    print "tc filter add dev eth1 protocol ip parent 1:0 prio 100 u32 ht $ip[2]:$ip[3]: match ip dst $row[2] flowid 1:$rule\n";
    if ($ip[0] eq 192 && $ip[1] eq 168) {
      $netb = $corp{$ip[2]};
    }
    if ($ip[0] eq 194) {
      $netb = $real{$ip[2]};
    }
    printf("tc filter add dev eth1 protocol ip parent 1:0 prio 10 u32 ht %x:%x: match ip dst $row[2] flowid 1:$rule\n", $netb, $ip[3]);
    $id = $row[0];
  }
  return $rule;
}


sub rule {
  local $string = $_[0];
  local $src, $dst;
  local %filter = ();
  $src = $dst = '';
  if ($string =~ /\,/) {
    ($src, $dst) = split(",", $string);
  }
  else {
    $dst = $string;
  }
  $string = '';
  if ($src ne '') {
    $src = trim($src);
    if ($src =~ /\:/) { ($filter{'srchost'}, $filter{'srcport'}) = split(":", $src) }
      else { $filter{'srchost'} = $src }
    $string .= "match ip src " . $filter{'srchost'} . " " if ($filter{'srchost'} ne '');
    $string .= "match ip sport " . $filter{'srcport'} . " 0xffff " if ($filter{'srcport'} ne '');
  }
  if ($dst ne '') {
    $dst = trim($dst);
    if ($dst =~ /\:/) { ($filter{'dsthost'}, $filter{'dstport'}) = split(":", $dst) }
      else { $filter{'dsthost'} = $dst }
    if ($filter{'dsthost'} ne '') {
      $string .= "match ip dst " . $filter{'dsthost'} . " ";
    }
    $string .= "match ip dport " . $filter{'dstport'} . " 0xffff " if ($filter{'dstport'} ne '');
  }
  return $string;
}

sub trim {
  local $str = $_[0];
  $str =~s/^ //g;
  $str =~ s/ $//g;
  return $str;
}
