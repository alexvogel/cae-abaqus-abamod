use strict;
use Test;

BEGIN {
	plan tests => 10
}

use File::Basename;
my ($filename, $directories, $suffix) = fileparse ($0);

use CAE::Abaqus::Abamod;

#------------------------------
# 1) testing full import
{
	my $model = CAE::Abaqus::Abamod->new();
	$model->importData("spl/abamodel.inc");
	
	# entity count
	ok($model->count(), 16);
	
	# import the same model again
	$model->importData("spl/abamodel.inc");

	# entity count
	ok($model->count(), 32);
}
#------------------------------

