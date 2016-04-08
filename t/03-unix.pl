#! /usr/bin/perl

use strict;
use warnings;

use lib qw(blib/lib lib);

my $server = MyServer->new()->run();

package MyServer;

use base qw( Net::Server::SS::PreFork );
use Server::Starter qw(server_ports);

sub new {
  my ($class) = @_;

  return $class->SUPER::new({
    proto => 'unix',
    port  => (values %{Server::Starter::server_ports()})[0],
  });
}

sub process_request {
  print getppid, "\n";
}

1;
