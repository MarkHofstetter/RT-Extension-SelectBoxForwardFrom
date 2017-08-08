package RT::Ticket;

use strict;
use warnings;
no warnings qw(redefine);

=head2 Forward Transaction => undef, To => '', Cc => '', Bcc => ''

Forwards transaction with all attachments as 'message/rfc822'.

=cut

sub Forward {
    my $self = shift;
    my %args = (
        Transaction    => undef,
        Subject        => '',
        To             => '',
        Cc             => '',
        Bcc            => '',
        Content        => '',
        ContentType    => 'text/plain',
        DryRun         => 0,
        CommitScrips   => 1,
        @_
    );

    unless ( $self->CurrentUserHasRight('ForwardMessage') ) {
        return ( 0, $self->loc("Permission Denied") );

    }

    $args{$_} = join ", ", map { $_->format } RT::EmailParser->ParseEmailAddress( $args{$_} || '' ) for qw(To Cc Bcc);

    return (0, $self->loc("Can't forward: no valid email addresses specified") )
        unless grep {length $args{$_}} qw/To Cc Bcc/;

    my $mime = MIME::Entity->build(
        Type    => $args{ContentType},
        Data    => Encode::encode( "UTF-8", $args{Content} ),
    );

    $mime->head->replace( $_ => Encode::encode('UTF-8',$args{$_} ) )
      for grep defined $args{$_}, qw(Subject To Cc Bcc From);

    $RT::Logger->info('***'. $args{From});
    if ($args{From}) {
        $mime->head->replace(
            From => $args{From}
        );
    } else {
       $mime->head->replace(
           Encode::encode( 'UTF-8',
            RT::Interface::Email::GetForwardFrom(
                Transaction => $args{Transaction},
                Ticket      => $self,
              )
           )
       );
    }

    if ($args{'DryRun'}) {
        $RT::Handle->BeginTransaction();
        $args{'CommitScrips'} = 0;
    }

    my ( $ret, $msg ) = $self->_NewTransaction(
        $args{Transaction}
        ? (
            Type  => 'Forward Transaction',
            Field => $args{Transaction}->id,
          )
        : (
            Type  => 'Forward Ticket',
            Field => $self->id,
        ),
        Data  => join( ', ', grep { length } $args{To}, $args{Cc}, $args{Bcc} ),
        MIMEObj => $mime,
        CommitScrips => $args{'CommitScrips'},
    );

    unless ($ret) {
        $RT::Logger->error("Failed to create transaction: $msg");
    }

    if ($args{'DryRun'}) {
        $RT::Handle->Rollback();
    }
    return ( $ret, $self->loc('Message recorded') );
}

1;

