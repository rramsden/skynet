#!/usr/bin/perl

use strict;
use warnings;

use NetSNMP::OID(':all');
use NetSNMP::agent(':all');
use NetSNMP::ASN(':all');
use IPC::ShareLite;
use lib "/home/rramsden/Projects/Github/skynet/scada";
use Driver;
use vars qw($agent);

use constant {
  FAILURE => 0,
  SUCCESS => 1
};

my $OID_ROOT       = ".1.3.6.1.4.1.8072.9999.9999.2";
my $OID_LOCK       = new NetSNMP::OID( $OID_ROOT . ".0" );
my $OID_STATUS     = new NetSNMP::OID( $OID_ROOT . ".1" );
my $OID_GOTO       = new NetSNMP::OID( $OID_ROOT . ".2" );
my $OID_LOCATION   = new NetSNMP::OID( $OID_ROOT . ".3" );

my $current_session = "";

my $status_ = IPC::ShareLite->new(
 -key => 13371,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $goto_ = IPC::ShareLite->new(
 -key => 13372,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $where_ = IPC::ShareLite->new(
 -key => 13373,
 -create => 'yes',
 -destroy => 'no') or die $!;
my $lock_ = IPC::ShareLite->new(
 -key => 13374,
 -create => 'yes',
 -destroy => 'no') or die $!;

# INITIALIZERS
$lock_->store(0);

sub handler {
  my ($handler, $registration_info, $request_info, $requests) = @_;
  my $request;

  for($request = $requests; $request; $request = $request->next()) {
    my $oid = $request->getOID();
    my $mode = $request_info->getMode();
    my $val = $request->getValue(); $val =~ s/\"//g;
    my $status = $status_->fetch();
    my $lock_timer = $lock_->fetch();
    my $info = "Unknown";

    if ($status == Driver::GOTO) {
      $info = "goto in progress";
    } elsif ($status == Driver::IDLE) {
      $info = "telescope idle";
    } elsif ($status == Driver::NOT_ALIGNED) {
      $info = "telescope is not aligned";
    }

    print "[STATUS] : " . $info . "\n";

    # EXPIRE SESSION
    if ($lock_timer == 0) { $current_session = ""; }

# ===== Getters ====== #

    if ($mode == MODE_GET) {
      print "MODE_GET\n";
      if ($oid == $OID_STATUS) {
        $request->setValue(ASN_INTEGER, $status_->fetch());
      }

      if ($oid == $OID_LOCATION) {
        my $whereami = $where_->fetch();
        $request->setValue(ASN_OCTET_STR, $whereami);
      }
    }

# ===== Setters ====== #

    if ($mode == MODE_SET_ACTION) {
      print "MODE_SET_ACTION\n";
      #=================
      #  REQUEST LOCK
      #=================
      if ($oid == $OID_LOCK) {
        if ($current_session eq "") {
          $current_session = $val;
          $request->setValue(ASN_OCTET_STR, "{\"sid\": \"".$val."\"}");
          $lock_->store(10);
        } else {
          $request->setValue(ASN_OCTET_STR, "{\"locked\": ".$lock_timer."}");
        }
      }

      #==================
      #  GOTO
      #==================
      if ($oid == $OID_GOTO) {

        if ($status == Driver::IDLE) {
          my ($sessionid,$ra,$dec) = split(",", $val);

          # check lock
          if ($sessionid eq $current_session && $current_session ne "") {
            $goto_->store($ra . "," . $dec);
            $request->setValue(ASN_INTEGER, SUCCESS);
            $status_->store( Driver::GOTO );
          } else {
            $request->setValue(ASN_OCTET_STR, "{\"error\": \"Session Invalid\"}");
          }
        } else {
          $request->setValue(ASN_OCTET_STR, "{\"error\": \"".$info."\"}");
        }

      }
    }
  }
}

$agent->register("skynet", $OID_ROOT, \&handler);
