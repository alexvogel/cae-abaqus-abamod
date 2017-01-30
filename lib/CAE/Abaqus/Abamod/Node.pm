package Node;

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

sub get_nid
{
	my $self = shift;
	$self->get_databit(1);
}

sub get_x
{
	my $self = shift;
	$self->get_databit(2);
}

sub get_y
{
	my $self = shift;
	$self->get_databit(3);
}

sub get_z
{
	my $self = shift;
	$self->get_databit(4);
}

sub get_xyz
{
	my $self = shift;
	my @xyz;
	push @xyz, $self->get_databit(2);
	push @xyz, $self->get_databit(3);
	push @xyz, $self->get_databit(4);
	return @xyz;
}

1;
