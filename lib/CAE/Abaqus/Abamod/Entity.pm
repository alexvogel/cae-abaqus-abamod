package CAE::Abaqus::Abamod::Entity;

use strict;
use vars qw($VERSION $DATE);
use Digest::MD5;

$VERSION           = '[% version %]';
$DATE              = '[% date %]';

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self={};
    
    $self =
    {
    	"comment" => [],
    	"starkey" => "unnamed",
		"param"   => {},
		"parammd5"=> undef,
        "data"    => [],
    };
    
    bless ($self, $class);
    return $self;
}

#---------------------
# sets the comment
# setComment(\@comment)
# return: -
#---------------------
sub setComment
{
	my $self = shift;
	$self->{'comment'} = shift;
}
#---------------------

#---------------------
# sets the starkey
# setStarey($string)
# return: -
#---------------------
sub setStarkey
{
	my $self = shift;
	$self->{'starkey'} = shift;
}
#---------------------

#---------------------
# sets the param
# setParam(\%param)
# return: -
#---------------------
sub setParam
{
	my $self = shift;
	$self->{'param'} = shift;
	$self->calcParamMd5()
}
#---------------------

#---------------------
# calculates a new checksum for param
# calcParammd5()
# return: -
#---------------------
sub calcParamMd5
{
	my $self = shift;
	my $paramAsString = $self->{'starkey'};
	
	foreach my $key (sort keys %{$self->{'param'}})
	{
		$paramAsString .= $key . ${$self->{'param'}}{$key};
	}
	
	$self->{'parammd5'} = Digest::MD5->md5($paramAsString);
#	print "PARAMASSTRING: " . $paramAsString . "\n";
#	print "PARAMASMD5: " . $self->{'parammd5'} . "\n";
}
#---------------------

#---------------------
# sets the data
# setData(\@data)
# return: -
#---------------------
sub setData
{
	my $self = shift;
	$self->{'data'} = shift;
}
#---------------------

#---------------------
# sets the data for a certain column
# setCol(int, $data)
# return: -
#---------------------
sub setCol
{
	my $self = shift;
	$self->{'data'}->[$_[0]] = $_[1];
}
#---------------------

#---------------------
# gets the data of a certain column
# getCol(int)
# return: $string
#---------------------
sub getCol
{
	my $self = shift;
	return $self->{'data'}->[$_[0]];
}
#---------------------

#---------------------
# gets the paramMd5
# getParamMd5()
# return: md5
#---------------------
sub getParamMd5
{
	my $self = shift;
	return $self->{'parammd5'};
}
#---------------------

#---------------------
# sets the param
# setParam($string)
# return: -
#---------------------
sub add_data
{
	my $self = shift;

	unless ($self->{'starkey'}) {$self->{'starkey'} = ref($self);}
	$self->{'param'} = shift;
	$self->{'data'} = shift if @_;
#	print "DEBUG: ".$self->{'key'} . "\n";
#	my $paramstring;
#	foreach my $param ( keys %{$self->{'param'}} )
#	{
#		$paramstring .= $param;
#	}
#	print "DEBUG: ". $paramstring . "\n";
#	if (exists $self->{'data'}) {print "DEBUG: ".@{$self->{'data'}} . "\n";}
}


#---------------------
# prints the data, if the flagParam == true, then the keyline is also printed
# print($flagParam)
# return: -
#---------------------
sub print
{
	my $self = shift;
	my $flagParam = shift;

	if($flagParam)
	{
		my $keyline = "*" . $self->{'starkey'};
	
		foreach my $param (sort keys %{$self->{'param'}})
		{
			$keyline .= ", ".$param;
			
			if(${$self->{'param'}}{$param})
			{
				$keyline .= "=" . ${$self->{'param'}}{$param};
			}
		}

		print $keyline."\n";
	}

	my $dataline;
	for(my $x=0, my $col=1; $x<@{$self->{'data'}}; $x++, $col++)
	{
		unless (${$self->{'data'}}[$col] =~ m/^\s*$/)
		{
			$dataline .= ${$self->{'data'}}[$col] . ",";
		}
	}
	chop $dataline;
	print $dataline . "\n";
}


sub printAlt
{
	my $self = shift;
#	print "this is an instance of '" . ref($self) . "'\n";
	my $output_keyline = "\*";
	$output_keyline .= $self->{'key'};

	foreach my $param (sort keys %{$self->{'param'}})
	{
		$output_keyline .= ", " . $param . "=" .   $self->{'param'}->{$param};
	}
	$output_keyline .= "\n";
	print $output_keyline;

	print join(",", @{$self->{'data'}}) . "\n" if defined $self->{'data'};
}

sub print_data
{
	my $self = shift;
	my $data = $self->sprint_data();
	print $data;
}

sub sprint_data
{
	my $self = shift;
	return join(",", @{$self->{'data'}}) . "\n" if defined $self->{'data'};
}

# es wird geprueft, ob das objekt einem bestimmten muster entspricht
# es wird entgegengenommen:
# 1) regex des abakeys ('node' matcht nur *node. 'set' matcht *nset und *elset, etc.)
# 2) referenz eines hashes, der key=value Paarungen von Abaqus Schluesselzeilen enthaelt. key und value sind regexe. z.B. 'INPUT=>.*\.inc' matcht auf alle entities, die als Schluesseldefinition INPUT=*.inc enthalten.
# 3) referenz eines arrays, soll regexe der einzelnen spalten enthalten. z.B. $data[0]=1827 matcht auf einen knoten mit der nid 1827
sub match
{
	my $self = shift;
	my $regex_abakey = shift if @_;
	my $refh_param = shift if @_;
	my $refa_data = shift if @_;
	my $gefunden;

	unless ($self->{'starkey'} =~ /^$regex_abakey$/i)
	{
		return undef;
	}

# check das %param auf uebereinstimmung. sobald ein definiertes Muster aus $refh_param nicht 'matcht' wird 'undef' zurueckgegeben.
	if ($refh_param)
	{
		foreach my $key (keys %$refh_param)
		{
			if (exists $self->{'param'}->{$key})
			{
				unless ($self->{'param'}->{$key} =~ m/^$$refh_param{$key}$/i)
				{
					return undef;
				}
			}
			else
			{
				return undef;
			}
		}
	}

# check das @data auf uebereinstimmung. sobald ein definiertes Muster aus $refa_data nicht 'matcht' wird 'undef' zurueckgegeben.
#	print "Anzahl der Stellen :" . scalar(@$refa_data) . ": @$refa_data\n";
	if ($refa_data)
	{
		for(my $x=0; $x<scalar(@$refa_data); $x++)
		{
			if (exists $$refa_data[$x])
			{
				print "checking " . ${$self->{'data'}}[$x] . " =? " . $$refa_data[$x] . "\n";
				
				foreach my $databit (@{$self->{'data'}})
				{
					print"lulu: $databit\n";
				}
				
				if ($self->{'data'}->[$x] =~ m/^$$refa_data[$x]$/)
				{
					$gefunden = 1;
				}
				else
				{
					return undef;
				}
			}
			else
			{
				return undef;
			}
		}
	}
	else
	{
		$gefunden = 1;
	}

# alle pruefungen wurden ueberstanden. das objekt wird zurueckgegeben.
	if ($gefunden)
	{
#		print "SELF: $self\n";
#		$self->print();
		return $self;
	}
}

#sub get_param
#{
#	my $self = shift;
#	return $self->{'param'};
#}

sub get_data
{
	my $self = shift;
	return $self->{'data'};
}

# ermitteln eines eintrages (spalte) innerhalb einer datenzeile
# rueckgabe eines wertes
sub get_databit
{
	my $self = shift;
	my $col = shift;
	my $index = $col-1;
	
	return $self->{'data'}->[$index] if exists $self->{'data'}->[$index];
}

# ermitteln eines eintrages (spalte) innerhalb einer datenzeile
# rueckgabe aller werte
sub get_databits
{
	my $self = shift;
	
#	print $self->{'data'} . "\n";
	return @{$self->{'data'}} if exists $self->{'data'};
}

# extrahiert den wert eines beliebigen parameters
# prototyp: $1=parameterstring
# z.B. object->get_param(TYPE);
sub get_param
{
	my $self = shift;
	my $param_to_get = lc shift;

	if (exists $self->{'param'}->{$param_to_get})
	{
		return $self->{'param'}->{$param_to_get};
	}
	else
	{
		return undef;
	}

}

1;