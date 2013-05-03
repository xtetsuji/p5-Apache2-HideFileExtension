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
    my $filename = $r->filename;

    $hide_ext = '.' . $hide_ext if 0 != index $hide_ext, '.';

    if ( $filename =~ /\Q$hide_ext\E$/ ) {
        my $schema = 'http://'; # for HTTP redirect. TOOD: under SSL env?
        my $url    = $schema . $r->hostname . $r->uri;
        $url =~ s/\Q$hide_ext\E$//
            or return Apache2::Const::DECLINED;
        $r->headers_out->set( Location => $url );
        return Apache2::Const::HTTP_MOVED_TEMPORARILY;
    }
    elsif ( -f $filename . $hide_ext ) {
        my $new_uri = $r->uri . $hide_ext;
        $r->internal_redirect($new_uri);
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

This modules hide your specify file extension on some context
(e.g. E<lt>DirectoryE<gt>, E<lt>LocationE<gt> and so on.).

=head1 MECHANISM

This module is recommended to hook at B<PerlHeaderPerserHandler>,
because we want to finished "URL Trans Phase" (PerlTransHandler) and
"Map to Storage Phase" (PerlMapToStorageHandler).
In this situation, finally URL and it's file path are determined.

This module searches either the file path is exists or not.
If it is exists, then the module send redirection url without extension.

Or the module gives request without the extension,
it causes Apache internal redirect with the extension.
Of course, this module ignores internal redirect's sub-request for
avoid infinite loop.

Apache internal redirect (Apache default-handler) handlings
some troublesome HTTP request processing,
e.g. HTTP 206 Partial Request, and so on.

If you understand mod_perl2 mechanism, and you run other rewrite process
at following native handler or Perl*Handler,
you can set this module at PerlFixupHandler.

Caution if you use mod_rewrite at E<lt>DirectoryE<gt> context,
then mod_rewrite may work something at fixup-handler.

=head1 SEE ALSO

L<Description of HeaderParserhandler|http://perl.apache.org/docs/2.0/user/handlers/http.html#PerlHeaderParserHandler>

=head1 AUTHOR

OGATA Tetsuji, E<lt>ogata {at} gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
