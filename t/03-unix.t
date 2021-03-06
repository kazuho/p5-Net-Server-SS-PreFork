use strict;
use warnings;

use LWP::Simple;
use Test::UNIXSock;
use Test::More tests => 3;
use IO::Socket::UNIX;

use Server::Starter qw(start_server);

test_unix_sock(
    server => sub {
        my $path = shift;
        start_server(
            path => $path,
            exec => [ $^X, qw(t/03-unix.pl) ],
        );
    },
    client => sub {
        my ($path, $server_pid) = @_;
        sleep 1;
        my $socket = IO::Socket::UNIX->new(
          Peer => $path,
        ) or die "failed to connect to unix socket:$!";
        chomp(my $worker_pid = <$socket>);
        like($worker_pid, qr/^\d+$/, 'send request and get pid');
        $socket->close;
        kill 'HUP', $server_pid;
        sleep 5;
        $socket = IO::Socket::UNIX->new(
          Peer => $path,
        ) or die "failed to connect to unix socket:$!";
        chomp(my $new_worker_pid = <$socket>);
        like($new_worker_pid, qr/^\d+$/, 'send request and get pid');
        isnt($worker_pid, $new_worker_pid, 'worker pid changed');
        $socket->close;
    },
);
