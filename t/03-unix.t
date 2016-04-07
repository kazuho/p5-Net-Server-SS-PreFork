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
            exec => [ $^X, qw(t/01-httpd.pl) ],
        );
    },
    client => sub {
        my ($path, $server_pid) = @_;
        sleep 1;
        printf( "path = %s\n" , $path);
        my $worker_pid;
        my $new_worker_pid;
        my $socket = IO::Socket::UNIX->new(
          Type => SOCK_STREAM,
          Peer => $path,
        );
        chomp( $worker_pid = <$socket>) ;
        like($worker_pid, qr/^\d+$/, 'send request and get pid');
        kill 'HUP', $server_pid;
        sleep 5;
        chomp( $new_worker_pid = <$socket>);
        like($new_worker_pid, qr/^\d+$/, 'send request and get pid');
        isnt($worker_pid, $new_worker_pid, 'worker pid changed');
    },
);
