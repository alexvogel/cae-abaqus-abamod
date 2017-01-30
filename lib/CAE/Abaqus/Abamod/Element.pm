package Element;

use strict;
use vars qw($VERSION @ISA $DATE);

our @ISA          = qw(Entity);
$VERSION          = '[% version %]';
$DATE             = '[% date %]';

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self={};
    
    $self =
    {
    	"key"    => undef,
		"param"  => undef,
        "data"   => undef,
    };
        
    bless ($self, $class);
    return $self;
}



sub get_eid
{
	my $self = shift;
	$self->get_databit(1);
}

sub get_nid1
{
	my $self = shift;
	$self->get_databit(2);
}

sub get_nid2
{
	my $self = shift;
	$self->get_databit(3);
}

sub get_nid3
{
	my $self = shift;
	$self->get_databit(4);
}

sub get_nid4
{
	my $self = shift;
	$self->get_databit(5);
}

# extrahiert den Wert des Parameters "ELSET"
sub get_name
{
	my $self = shift;
	$self->get_param("elset");
}

sub normale
{
	my $self = shift;
	unless ($self->{'param'}->{'type'} =~ m/S3|S4/i)
	{
		return undef;
	}
	
	
	$self->get_nid1;
	my $nid2 = $self->get_nid1;
	my $nid3 = $self->get_nid1;

}

1;