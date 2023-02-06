use strict;
use warnings;

use File::Temp;
use LWP::Simple;
use Test::TCP;
use Test::More;

use Server::Starter qw(start_server);

my $num_tests = 5;

eval { require Net::Server::Proto::SSL };
if ($@) {
    plan skip_all => "Net::Server::Proto::SSL is required to run $0", $num_tests;
    exit 0;
}
eval { require LWP::Protocol::https };
if ($@) {
    plan skip_all => "LWP::Protocol::https is required to run $0", $num_tests;
    exit 0;
}

plan tests => $num_tests;



my $pem_file = setup_cert_files();

$ENV{t_04_ssl_t} = "pid $$ at ".time; # used in 04-ssl.pl
my $Expected_Response = "Hello, $ENV{t_04_ssl_t}";

test_tcp(
    server => sub {
        my $port = shift;
        start_server(
            port => $port,
            # can also use: port => "$port:ssl",
            # instead of --SSL argument below which makes all the ports SSL
            exec => [ $^X,
                '-Ilib',
                't/04-ssl.pl',
                '--SSL',
                '--SSL_cert_file', $pem_file,
                '--SSL_key_file', $pem_file,
            ],
        );
    },
    client => sub {
        my ($port, $server_pid) = @_;
        sleep 1;
        my $ua = LWP::UserAgent->new(
             ssl_opts => {
                 verify_hostname => 0,
             }
         );

        my $proto = 'https';
        my $req = HTTP::Request->new(GET => "$proto://127.0.0.1:$port/");

        $req->header(Host => 'server.local'); # to match the cert

        my $res = $ua->request($req);

        if ($res->is_success) {
            like($res->decoded_content, qr/$Expected_Response/, 'sent request and got response');
            my %ssl_headers = (
                'Client-SSL-Cert-Issuer'  => '/CN=IO::Socket::SSL Demo CA',
                'Client-SSL-Cert-Subject' => '/CN=server.local',
                'Client-SSL-Socket-Class' => 'IO::Socket::SSL',
                'Client-SSL-Warning'      => 'Peer certificate not verified',
                # these vary:
                #'Client-SSL-Cipher'       => 'TLS_AES_256_GCM_SHA384',
                #'Client-SSL-Version'      => 'TLSv1_3',
            );
            foreach my $header (sort keys %ssl_headers) {
                my $expected = $ssl_headers{$header};
                is $res->header($header), $expected, "response $header = $expected ok";
            }

        } else {
            die $res->status_line;
        }

    },
);

sub setup_cert_files {

    # this certificate is invalid, please only use for testing (IO::Socket::SSL's server-wildcard.pem)
    my $pem = << 'PEM';
-----BEGIN CERTIFICATE-----
MIIDpDCCAoygAwIBAgIEU2/kRTANBgkqhkiG9w0BAQsFADAiMSAwHgYDVQQDDBdJ
Tzo6U29ja2V0OjpTU0wgRGVtbyBDQTAeFw0yMTA4MTYwODI2NDlaFw0zMTA4MTQw
ODI2NDlaMBcxFTATBgNVBAMMDHNlcnZlci5sb2NhbDCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAOWgEMbF77Jgmz9h9WHA76RGmeyZ6g34EfwdP1mGyBgT
29QxGa1bs3N9j874lsvgpCc4HfL0zzOsa/0SEE8BM5a71QUbcDqMoKm3H9UAqmK9
YoKaxotvqmMkXYl+d3qkF1H4zDx8ZMLFRX9o3gC2Ot043X/djiaa8BP7YdLu4Q8G
VmSnFcpNehFkJAmt/cV3ehrJqU9oKzyDHiWB8rCxY17TU8BIgTTyQwlgnZ2oYpLU
zuSJPem9RRQhaPnCuuqwaWG2JqDppwRuyqUictZcwUcdazpxI0YyGP0G8x3pkqTb
Vi+BA5UgMG/GjuYcP3sx4Dxb7cmnF0kCqe7eclR3qrECAwEAAaOB7DCB6TAdBgNV
HQ4EFgQU9T053wvf56DXyotfQv+lhyR/SR4wHwYDVR0jBBgwFoAUueKHd8JzjKB1
KKYF4Fi9TmDD3zcwYQYDVR0RBFowWIIOKi5zZXJ2ZXIubG9jYWyHBH8AAAGCEHd3
dyoub3RoZXIubG9jYWyCE3NtdHAubXlkb21haW4ubG9jYWyCGXhuLS1sd2Utc25h
LmlkbnRlc3QubG9jYWwwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCBaAwEQYJ
YIZIAYb4QgEBBAQDAgZAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqGSIb3DQEB
CwUAA4IBAQCpy5NfTKJ3IYlIj+5wnJCRJQsizHUPnNnM00qlkGnDjtoJGmq4p/kX
uJfMZqrbHYz8THz+qCGf4EeW36Bu0V5OQm2mIpJ1ufHeIMkZVOyxSzG6blZtdHRE
SgFC1TnTA9bw9e8dlr9IuTeIfxbyq7cfyLdh/ecIlSoaQ00lPY2Hxp1IOjMIbvfT
kb3T/WiPLs+/u8mcqABbSiFX/XHaeqUs7kkE5W3LYwAcyaH+3xVxrBkw8IBRR9yY
+/orXxElNACATVfg+SxUSWsT7Nb1ZEkSP9njnhEYb02JbrbF+ZWTInNXS+7WPdbz
NuvgXlercSqSM2xeaqkQQ//bjbTw4+7x
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDloBDGxe+yYJs/
YfVhwO+kRpnsmeoN+BH8HT9ZhsgYE9vUMRmtW7NzfY/O+JbL4KQnOB3y9M8zrGv9
EhBPATOWu9UFG3A6jKCptx/VAKpivWKCmsaLb6pjJF2Jfnd6pBdR+Mw8fGTCxUV/
aN4AtjrdON1/3Y4mmvAT+2HS7uEPBlZkpxXKTXoRZCQJrf3Fd3oayalPaCs8gx4l
gfKwsWNe01PASIE08kMJYJ2dqGKS1M7kiT3pvUUUIWj5wrrqsGlhtiag6acEbsql
InLWXMFHHWs6cSNGMhj9BvMd6ZKk21YvgQOVIDBvxo7mHD97MeA8W+3JpxdJAqnu
3nJUd6qxAgMBAAECggEAJMSyqwF61jc95LJM1nBMbyOW9hnXLpFwX8xXHoDEfYaA
hsOt9uJeI7oRUvTfQJoh7t2/fe3RV9beG9HOprfsiNBe1ciE+fsWptZZ1IOcxN7K
bVtXO3CP+fwStjd37j1kNo3+Nhk9ESsBa9tg4QBNAKtgXF8fqfLZSnnQOjRh+UOe
3U4yCvg33+UuAjqOquhMK6fb0uYDkaOPE1oeN8c721aSzl+zHXyO/fcjHQyrAVRK
DPpzKc90Qf3SQzlGDibLhcm9iiyAxdw7hjr4SAyuqbaWwSwihkbU9wUj3b7W1rsV
bdJ+GH8fusPM9pVwkBqavszUAfTxDYDqy0Zd9mYxuQKBgQD2vr0JqRiBdGsCfdnY
0DukW5ZWAcWRfrJ+eSRdgMHF5jn9fznI0BQkXg4q3LJr2U2iiVrkfYsC/+mOqyPO
puWe4UcXiitIBNCBBY7DFxrulK31HCihapni1lv+8f4HKotxTXthvbdv4jHd0lso
Yb/fOawEGV7gXmn4BX0IFik5BwKBgQDuPPEKS8tFmcavS4KLxWVtJIlBxO4doPPh
nWghwM5l7zJKFRXnpHLeQQGHSim6eCq7U/8qh4Dn1NabyCreniFNomjUiw60a6nE
qO63PGEg8jjOMI7FneQlnWtoaoAL86d3xE+ZeWkKFPvjhDRzOcO0xD8j064pGRgH
b3muoMKohwKBgQCOlkrHemAe7xenqPJqyGqu3/5QVVXGbmDXlUnefrl7kz+PriXG
VfhNy8yEGGVCzaB/fMB5qdLbOOfO+jcHBItM9QIQKFg6lg2ngX6uXnvBw0mDi3Iv
VVr4Ksee3Fjf60YJg6z5HpkSnrQSa60h+NrYNIujEsYxAl5aZVGLisLnoQKBgH3M
dENJjoasErwRlVeU3l/pgQjXohzHFsC1y3y3QMWWrulrhOuSbI1rqhD0WmB6f6X3
Tq/4aVsBimksI2b1/QPvlIdW/mbKyxRrV9It8ePhw5ktDtbO7t/l5gd25TJqcK3P
XXDfKVYHipKzBrcpc2wKjISwjDBrbcLPXGOXw/IVAoGBAJb0t/E7O8MoUb74in9z
H+XH9u8wsfd5Av1t/HKSFT26psj9jRNUrG1qhE/Nq7xD9CWqQz/2b5hv3WsyBrx9
Gi96HjkVa8b5q56yXSrF1nnaII6omP10A1ytReM//N+D9tJCg2zRtGdVwDReBo9+
c4tEO980MgyYSWrlbyZO0EnM
-----END PRIVATE KEY-----
PEM

    my ($pem_fh, $pem_filename) =
      File::Temp::tempfile(SUFFIX => '.pem', UNLINK => 1);
    print $pem_fh $pem;
    $pem_fh->close;

    return $pem_filename;
}
