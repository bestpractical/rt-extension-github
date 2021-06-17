use strict;
use warnings;
package RT::Extension::GitHub;

use URI::Escape;
use LWP::UserAgent ();
use JSON;

our $VERSION = '0.01';

RT->AddStyleSheets('github-actions.css');
RT->AddJavaScript('github-actions.js');

=head1 NAME

RT-Extension-GitHub - Tools to integrate RT with GitHub

=head1 DESCRIPTION

This extension provides tools and features that are useful if you
use GitHub for version control and possibly GitHub Actions for CI
and you track your work in RT.

=head1 RT VERSION

Works with RT 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::GitHub');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 Queues for Github Actions

Set the following to define which queues should show the Github Actions
portlet with test results for a branch:

    Set( $GitHubActions, {
        Queues => [ 'General' ] }
    );

The extension expects the subject of tickets to be the name of the
branch to try to fetch test results for.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-GitHub@rt.cpan.org">bug-RT-Extension-GitHub@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GitHub">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-GitHub@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GitHub

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

sub GetBranchDetails {
    my $ticket = shift;
    my $subject = $ticket->Subject();

    # Trim leading and trailing whitespace from subject
    $subject =~ s/^\s+//;
    $subject =~ s/\s+$//;

    if ($subject =~ /^([A-Za-z_.-]+)[\/ ](.+)/) {
        RT->Logger->debug(
            "Extracted project '$1' and branch '$2' from ticket subject '$subject'");
        return ($1, $2);
    } else {
        my $proj = RT->Config->Get('GitHubActions')->{'DefaultProject'} // 'rt';
        RT->Logger->debug("Using ticket subject as branch '$subject' in project $proj");
        return ($proj, $subject);
    }
}

sub GetStatus {
    my $proj = shift;
    my $branch = shift;
    my $current_user = shift;

    my $ua = LWP::UserAgent->new();

    # curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/bestpractical/rt/actions/runs?branch='4.4/principals-autocomplete-callbacks'

    my $url = "https://api.github.com" . '/repos/' . 'bestpractical/' . uri_escape($proj) . '/actions/runs?branch=' . uri_escape($branch);
    my $response = $ua->get($url,
            'Accept' => 'application/vnd.github.v3+json',
        );

    if (!$response->is_success) {
        RT->Logger->error('Call to github failed: ' . $response->status_line );
        return 0;
    }

    my $result;
    eval {
        $result = decode_json($response->decoded_content);
    };
    if ($@) {
        RT->Logger->error("Could not parse JSON: $@");
        return 0;
    }

    return $result;
}

1;
