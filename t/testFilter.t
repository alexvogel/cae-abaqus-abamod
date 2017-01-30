use strict;
use Test;

BEGIN { plan tests => 8 }

use CAE::Abaqus::Abamod;

#------------------------------
# 1), 2) testing filter
{
	my $model = CAE::Abaqus::Abamod->new();
	$model->importData("spl/abamodel.inc");
	
	ok($model->count(), 16);

	my $starabakeyFilter = "ELEMENT";
    my %paramFilter = ("TYPE" => "S4");
    my @dataFilter  = ("6");

    # use only the starabakeyFilter
    my $filteredModel = $model->filter($starabakeyFilter);
	ok($filteredModel->count(), 4);
	$filteredModel->print();

    # use the starabakeyFilter and paramFilter
    my $filteredModel2 = $model->filter($starabakeyFilter, \%paramFilter);
	ok($filteredModel2->count(), 2);
	$filteredModel2->print();

    # use the starabakeyFilter and paramFilter and dataFilter
    my $filteredModel3 = $model->filter($starabakeyFilter, \%paramFilter, \@dataFilter);
	ok($filteredModel3->count(), 1);
	$filteredModel3->print();
}
#------------------------------

