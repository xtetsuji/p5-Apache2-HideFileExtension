package Apache2::HideFileExtension;
# PerlHeaderParserHandler Apache2::HideFileExtension

use strict;
use warnings;

use Apache2::Const -compile => qw(:common :http);
use Apache2::RequestRec  ();
use Apache2::RequestUtil (); # for is_initial_req
use Apache2::SubRequest  (); # for internal_redirect

our $VERSION = '0.01';

sub handler {
    my $r = shift;

    return Apache2::Const::DECLINED if !$r->is_initial_req;

    my $hide_ext = $r->dir_config->get('HideExtension') || '.html';
    my $schema   = 'http://'; # for internal redirect. TOOD: under SSL env?
    my $hostname = $r->hostname;
    my $uri      = $r->uri;
    my $filename = $r->filename;
    my $url      = $schema . $hostname . $uri;

    $hide_ext = '.' . $hide_ext if 0 != index $hide_ext, '.';

    if ( $filename =~ /\Q$hide_ext\E$/ ) {
        $url =~ s/\Q$hide_ext\E$//
            or return Apache2::Const::DECLINED;
        $r->headers_out->set( Location => $url );
        return Apache2::Const::HTTP_MOVED_TEMPORARILY;
    }
    elsif ( -f $filename . $hide_ext ) {
        $url .= $hide_ext;
        $r->internal_redirect($url);
        return Apache2::Const::OK;
    }

    return Apache2::Const::DECLINED;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Apache2::HideFileExtension - Access "/path/to/SOMEONE.html" as "/path/to/SOMEONE"

=head1 SYNOPSIS

  # in Apache config file. in <VirtualHost> or <Location>.
  <Location /path/to/htmldir>
    PerlHeaderParserHandler Apache2::HideFileExtension
    # ".html" is default.
    PerlSetVar HideExtension .html
  </Location>

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

OGATA Tetsuji, E<lt>ogata {at} gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
