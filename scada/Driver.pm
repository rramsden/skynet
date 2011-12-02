##
# Celestron NexStar Driver for GT Hand Remotes

package      Driver;
require      Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw(IDLE GOTO NOT_ALIGNED);
our %EXPORT_TAGS = ( consts => ['IDLE', 'GOTO', 'NOT_ALIGNED'] );

use Device::SerialPort;

use constant {
    IDLE   => 1,
    GOTO   => 2,
    NOT_ALIGNED => 3
};

my $sp;

sub new {
  my($class, $device) = @_;        # Class name is in the first parameter
  my $self = { device => $device };  # Anonymous hash reference holds instance attributes

  ###
  # Initialize Serial Device
  $sp = Device::SerialPort->new($device, 1, '/tmp/pwlock')  || die "Driver.pm: Cant Open Seriel Port \n";
  $sp->baudrate(9600);
  $sp->parity("none");
  $sp->handshake("none");
  $sp->databits(8);
  $sp->stopbits(1);
  $sp->read_char_time(0);
  $sp->read_const_time(1000); # Celestron recommends maximum of 300ms timeout

  bless($self, $class);
  return $self;
}

sub where {
  $sp->write("E");
  my($count, $saw) = $sp->read(255);
  chop($saw);

  my($ra, $dec, $rest) = split(",", $saw);

  $ra = ((hex($ra) / 65536) * 360) / 15.0;
  $dec = ((hex($dec) / 65536) * 360);

  return ($ra, $dec);
}

sub goto {
  my($class, $ra, $dec) = @_;

  $ra = $ra * 15.0;

  if ($dec < 0) {
    $dec = 360 + $dec;
  }

  $dec = int(($dec / 360.0) * 65536);
  $ra = int(($ra / 360.0) * 65536);

  $msg = "R" . sprintf("%04X",$ra) . "," . sprintf("%04X",$dec);
  $sp->write($msg);
  $sp->read(1);
  return 1;
}

sub status {
  $sp->write("L");
  my($count, $saw) = $sp->read(255);

  if ($saw eq "1#") {
    return GOTO;
  }

  if ($saw eq "0#") {
    return IDLE;
  }

  return NOT_ALIGNED;
}

sub close {
  $sp->close();
}

sub cancel_goto {
  $sp->write("M");
  $sp->read(1);
}

1;
