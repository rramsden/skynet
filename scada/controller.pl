#!/usr/bin/perl

$|=1;

use IPC::ShareLite;
use AnyEvent;
use Driver;

my $status = IPC::ShareLite->new(
 -key => 13371,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $goto = IPC::ShareLite->new(
 -key => 13372,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $where = IPC::ShareLite->new(
 -key => 13373,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $lock = IPC::ShareLite->new(
 -key => 13374,
 -create => 'yes',
 -destroy => 'no') or die $!;

my $driver = new Driver("/dev/pts/2");
sub leaveScript {
   if (defined($driver)) {
      $driver->close();
   }
   print ("Good Bye\n");
   exit;
}

$SIG{INT} = sub { do leaveScript(); };

$e_watch_goto = AnyEvent->timer(
  after => 0,
  interval => 1,
  cb => sub {
    $val = $goto->fetch();
    $state = $status->fetch();

    # failsafe make damn sure telescope is IDLE
    if ($val != "" && $state == Driver::IDLE) {
      # goto and clear buffer
      my($ra,$dec) = split(",", $val);
      $driver->goto( $ra + 0.0, $dec + 0.0 );
      $status->store( Driver::GOTO );
      $goto->store( "" ); 
    }
  }
);

$e_lock = AnyEvent->timer(
  after => 0,
  interval => 1,
  cb => sub {
    $lock_timer = $lock->fetch();

    # decrement lock timer
    if ($lock_timer > 0) {
      $lock->store( $lock_timer - 1 );
      print "Timer: " . ($lock_timer - 1) . "\n";
    }
  }
);

# periodically grabs telescope state
$e_watch_status = AnyEvent->timer(
  after => 0,
  interval => 1,
  cb => sub {
    local $state = $driver->status();
    if ($state != undef) {

      $status->store($state);
      ($ra, $dec) = $driver->where();

      if ($state == Driver::IDLE) {
        $where->store( "{\"ra\": ".$ra.", \"dec\": ".$dec."}");
      }

    } else {
      print "WARNING: bad read, watch_status\n";
    }
  }
);

$z_event = AnyEvent->condvar;
$z_event->recv;
