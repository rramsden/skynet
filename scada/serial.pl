#!/usr/bin/perl

$|=1;

use AnyEvent;
use Device::SerialPort;

my @stdin_fifo;
my @stdout_fifo;
my @task_fifo;
my $command;

sub leaveScript {
   if (defined($sp)) {
      $sp->close();
   }
   print ("Good Bye\n");
   exit;
}

sub trim {
    $_[0] = (($_[0] =~ /^[ \t]*(.*?)[ \t]*$/s)[0]);
}

$SIG{INT} = sub { do leaveScript();};

my $sp = Device::SerialPort->new("/dev/pts/5", 1, '/tmp/pwlock')  || die "Cant Open Seriel Port \n";
$sp->baudrate(9600);
$sp->parity("none");
$sp->handshake("none");
$sp->databits(8);
$sp->stopbits(1);
$sp->read_char_time(0);
$sp->read_const_time(100);
$sp->read(255); # clear junk data off

$z_event = AnyEvent->condvar;

print("shell: ");

sub to_f {
  return $_[0] + 0.0;
}

$process_stdout_ref = sub {
  while (@stdout_fifo > 0) {
    print(shift(@stdout_fifo));
  }
  print("shell: ");
};

$process_stdin_ref = sub {
  $command = shift(@stdin_fifo);

  ($cmd, $suffix) = split(" ", $command);

  if ($cmd eq "goto") {
    ($ra, $dec) = split(",", $suffix);
    $ra = trim($ra);
    $dec = trim($dec);

    $ra = to_f($ra) * 15.0;

    $dec = to_f($dec);
    if ($dec < 0) {
      $dec = 360 + $dec;
    }

    $dec = int(($dec / 360.0) * 65536);
    $ra = int(($ra / 360.0) * 65536);

    $msg = "R" . sprintf("%04X",$ra) . "," . sprintf("%04X",$dec);
    $sp->write($msg);
    $sp->read(1);

    push(@stdout_fifo, $msg);
    push(@task_fifo, $process_stdout_ref);
  } elsif ($cmd eq "right") {
    # IMPORTANT: MAKE SURE TRACKING MODE IS OFF
    $rate = 0;
    $send = "P" . chr(2) . chr(16) . chr(36) . chr($rate) . chr(0) . chr(0) . chr(0);
    $sp->write($send);
    $sp->read(1);
  } elsif ($cmd eq "left") {
    # IMPORTANT: MAKE SURE TRACKING MODE IS OFF
    $rate = 0;
    $send = "P" . chr(2) . chr(16) . chr(37) . chr($rate) . chr(0) . chr(0) . chr(0);
    $sp->write($send);
    $sp->read(1);
  } elsif ($cmd eq "whereami") {
    $sp->write("E");
    ($count, $saw) = $sp->read(255);
    chop($saw);

    print $saw . "\n";

    ($ra, $dec, $rest) = split(",", $saw);

    $ra = ((hex($ra) / 65536) * 360) / 15.0;
    $dec = ((hex($dec) / 65536) * 360);

    $msg = "RA,DEC: " . $ra . ", " . $dec . "\n";
    push(@stdout_fifo, $msg);
    push(@task_fifo, $process_stdout_ref);
  } elsif ($cmd eq "stop") {
    $sp->write("M");
    $sp->read(1);
  } elsif ($cmd eq "t") {
    $sp->write("t");
    ($count, $saw) = $sp->read(255);
    $msg = "";

    print "saw " . $saw . "\n";

    if ($saw eq (chr(0) . "#")) {
      $msg = "Off\n";
    }

    if ($saw eq (chr(1) . "#")) {
      $msg = "Alt/Az\n";
    }

    push(@stdout_fifo, $msg);
    push(@task_fifo, $process_stdout_ref);

  ###
  # SET TRACKING MODE OFF
  } elsif ($cmd eq "T") {
    $sp->write("T" . chr(0));
    $sp->read(1);
  } elsif ($cmd eq "aligned") {
    $sp->write("J");
    ($count, $saw) = $sp->read(255);
    print "saw: " . $saw . "\n";
    
    if ($saw eq (chr(0) . "#")) {
      $msg =  "Not aligned.\n";
    } else {
      $msg =  "Aligned.\n";
    }

    push(@stdout_fifo, $msg);
    push(@task_fifo, $process_stdout_ref);
  } else {
    push(@stdout_fifo, "invalid command\n");
    push(@task_fifo, $process_stdout_ref);
  }

};

###
# POLL STDIN
$b_event = AnyEvent->io(fh => \*STDIN, poll => "r", cb => sub {
  $line = <>;
  push(@stdin_fifo, $line);
  push(@task_fifo, $process_stdin_ref);
});

###
# IDLE EVENT LOOP
$c_event = AnyEvent->idle(cb => sub {
  $len = @task_fifo;
  if ($len > 0) {
    $sr = shift(@task_fifo);
    $sr->();
  }
});

$z_event->recv;
