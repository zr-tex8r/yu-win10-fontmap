use strict;
use Data::Dump 'dump';
my $prog_name = 'generate';

#---------------------------------------

my @target = qw(
otf-up-yu-win10.map
otf-yu-win10.map
ptex-yu-win10.map
uptex-yu-win10.map
);

sub mod_map_name {
  return $_[0]."-mod";
}
sub mod_cmap_name {
  return ("YuFont_".$_[0], $_[1], $_[2]);
}

sub main {
  my (%cmap);
  foreach my $fmap (@target) {
    create_mod_map_file($fmap, \%cmap);
  }
  foreach my $cmap (sort(keys %cmap)) {
    create_mod_cmap_file($cmap, \%cmap);
  }
}

#---------------------------------------

sub kpse_find {
  my ($name, @opt) = @_;
  local $_ = `kpsewhich @opt $name`; chomp($_);
  ($_ ne '') or error("file not found on search path", $name);
  return $_;
}

sub parse_cmap_name {
  local ($_) = @_; my @f = split(m/-/, $_);
  unshift(@f, "") while ($#f < 2);
  ($#f == 2 && $f[2] =~ m/^[HV]$/)
    or error("invalid cmap name", $_);
  return @f;
}
sub make_cmap_name {
  return join('-', grep { m/./ } (@_));
}

sub info {
  print STDERR (join(": ", $prog_name, @_), "\n");
}
sub error {
  info(@_); exit(-1);
}

#---------------------------------------

sub create_mod_map_file {
  my ($fmap, $rcmap) = @_; local ($_);
  my $pmap = kpse_find($fmap);
  info("convert map", $pmap);
  open(my $hi, '<', $pmap)
    or error("cannot open file for input", $pmap);
  $_ = $fmap; s/\.map//ai;
  my $fmmap = mod_map_name($_) . ".map";
  info("to", $fmmap);
  open(my $ho, '>', $fmmap)
    or error("cannot open file for output", $fmmap);
  binmode($hi); binmode($ho);
  while (<$hi>) {
    chomp($_);
    if (m/^\s*(?:[%#].*)?$/) {
      print $ho ("$_\n");
    } elsif (my @f = m/^(\s*\S+\s+)(\S+)(\s+[^\s\%\#,]+)(.*)$/) {
      my $cmap = $f[1];
      if (!exists $rcmap->{$cmap}) {
        $rcmap->{$cmap} = kpse_find($cmap, "--format=cmap");
        info("cmap is valid", $cmap);
      }
      $f[1] = make_cmap_name(mod_cmap_name(parse_cmap_name($cmap)));
      $f[2] =~ s|/\w+$||; $f[2] .= "/I";
      print $ho (@f, "\n");
    } else {
      error("Syntax error in map file");
    }
  }
  close($hi); close($ho);
}

#---------------------------------------

sub create_mod_cmap_file {
  my ($cmap, $rcmap) = @_; local ($_);
  my $pcmap = $rcmap->{$cmap};
  info("convert cmap", $pcmap);
  my @cmn = parse_cmap_name($cmap);
  my @mcmn = mod_cmap_name(@cmn);
  open(my $hi, '<', $pcmap)
    or error("cannot open file for input", $pcmap);
  my $mcmap = make_cmap_name(@mcmn);
  info("to", $mcmap);
  open(my $ho, '>', $mcmap)
    or error("cannot open file for output", $mcmap);
  binmode($hi); binmode($ho);
  while (<$hi>) {
    if (m|^%%BeginResource: CMap|) {
      print $ho ("%%BeginResource: CMap ($mcmap)\n");
    } elsif (m|^%%Title: |) {
      print $ho ("%%Title: ($mcmap Adobe Identity 0)\n");
    } elsif (m|^  /Registry|) {
      print $ho ("  /Registry (Adobe) def\n");
    } elsif (m|^  /Ordering|) {
      print $ho ("  /Ordering (Identity) def\n");
    } elsif (m|^  /Supplement|) {
      print $ho ("  /Supplement 0 def\n");
    } elsif (m|^/CMapName |) {
      print $ho ("/CMapName /$mcmap def\n");
    } elsif (m|^/XUID |) {
    } elsif (m|^/UIDOffset |) {
    } elsif (my @z = m|^(\s*<\w+>\s+(?:<\w+>\s+)?)(\d+)|) {
      $z[1] = $z[1] + 2;
      print $ho (@z, "\n");
    } else {
      print $ho ($_);
    }
  }
  close($hi); close($ho);
}

#---------------------------------------
main();
# EOF
