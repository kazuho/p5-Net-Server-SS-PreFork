#! /usr/bin/perl

use strict;
use warnings;
use Data::Dump qw/dump/;

use lib qw(blib/lib lib);

my $server = MyServer->new();
$server->run();

package MyServer;

use base qw( Net::Server::SS::PreFork );
use Server::Starter qw(server_ports);

sub new {
  my ($class) = @_;

  return $class->SUPER::new({
    proto => 'tcp',
    port  => (values %{Server::Starter::server_ports()})[0],
    ssl => 1,
  });
}


sub process_request {
    my ($myserver, $net_server_proto) = @_; # just to document the args

    print "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nHello, $ENV{t_04_ssl_t}"
}

1;
