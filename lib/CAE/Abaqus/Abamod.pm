package CAE::Abaqus::Abamod;

#require Exporter;

use strict;

use CAE::Abaqus::Abamod::Entity;
use vars qw($VERSION $ABSTRACT $DATE);

$VERSION           = '[% version %]';
$DATE              = '[% date %]';
$ABSTRACT          = 'basic access to abaqus models';

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self={};

    $self =
    {
        "content"  => [],
    };

    bless ($self, $class);
    return $self;
}

#---------------------
# prints the whole model, if path is given, then to file
# print(path)
# return: -
#---------------------
sub print
{
    my $self = shift;

	my $outfile = undef;
	if (@_)
	{
		$outfile = shift(@_);
		if (stat $outfile)
		{
			print("error: file does already exist. " . $outfile . "\n");
			return undef;
		}
	}

	# if an outfile has been defined, redirect STDOUT to this file
	if($outfile)
	{
		open (SAVE, ">&STDOUT") or die "can't save STDOUT $!\n";
		open (STDOUT, '>', $outfile) or die "can't redirect STDOUT to " . $outfile . ": $!";
	}

    my $flagClustered = "1";
    
    # if clustering is desired
    if($flagClustered)
	{
		my @allMd5 = $self->getParamMd5();
	
		foreach my $md5 (@allMd5)
		{
			my @allEntitiesOfACertainMd5 = $self->getEntityByParamMd5($md5);
			for(my $x=0; $x<@allEntitiesOfACertainMd5; $x++)
			{
				if($x == 0)
				{
					$allEntitiesOfACertainMd5[$x]->print("flagPrintWithParam");
				}
				else
				{
					$allEntitiesOfACertainMd5[$x]->print();
				}
			}
		}
	}

    # without clustering
	else
	{
		foreach my $entity (@{$self->{'content'}})
		{
			$entity->print("flagPrintWithParam");
		}
	}

	# remove redirection of STDOUT
	if($outfile)
	{
		close STDOUT;
		open (STDOUT, ">&SAVE") or die "can't restore STDOUT $!\n";
		close SAVE;
	}

	return "true";
}
#---------------------

#---------------------
# get a list of all used paramhashes
# getParamMd5
# return: -
#---------------------
sub getParamMd5
{
	my $self = shift;
	my %paramMd5;
	my $count = 0;
	my @count;

	foreach my $entity ($self->getEntity())
	{
		$paramMd5{$entity->getParamMd5()} = $count;
		push(@count, $count);
		$count++;
	}
	
	my @paramMd5TimeSorted;
	
	foreach my $c ( sort {$a <=> $b} @count )
	{
		foreach my $paramMd5 (keys %paramMd5)
		{
			if($paramMd5{$paramMd5} eq  $c)
			{
				push @paramMd5TimeSorted, $paramMd5;
				next;
			}
		}
	}
	
	return @paramMd5TimeSorted;
}
#---------------------

sub print_data
{
	my $self = shift;
	my $data = $self->sprint_data();
	print $data;
}

# rueckgabe der daten ohne schluesselzeilen
sub sprint_data
{
    my $self = shift;

	my $datalines;

	foreach my $entity (@{$self->{'content'}})
	{
		$datalines .= $entity->sprint_data();
	}
	return $datalines;
}


#---------------------
# importiere ein abaqus-modell aus einem file ins show
#---------------------

sub importData
{
    my $self = shift;
    my $path = shift;
    my $refh_options;

    if(@_)
    {
    	$refh_options = shift;
    }
	# my %OPTIONS = %$refh_options;

	my $starkey;

	my $param;

	my @starComment;
	my @comment;

	my $entity;
	my $dataLine = 0;

   	if (!open (ABAQUS, "<$path")) {die "FATAL: Cannot read $path $!\n";}
	my @allLines = <ABAQUS>;
	close ABAQUS;

	chomp @allLines;

	foreach my $line (@allLines)
	{
		$line =~ s/\s+//g;  # delete whitespaces

		# if its a comment
		if ($line =~ m/^\*\*(.*)$/)
		{
			# add line to current comment
			push(@comment, $1);
		}

		# if its an starkey line
		elsif ($line =~ m/^\*([^\*,]+)(.*)$/)
		{
			# reset param
			undef($starkey);

			# reset param
			my %param;
			$param = \%param;
			
			# promote comment to mainComment
			@starComment = @comment;
			undef(@comment);

			# set starkey
			$starkey = uc($1);

			my $paramString = $2;

			# set parameter (%param)
			foreach my $par (split(",", $2))
			{
				if ($par eq "") {next;}
				my @parChunks = split("=", $par);
				
				# if theres only 1 parChunk, then its a flag
				if(@parChunks == 1)
				{
					$param{$parChunks[0]} = undef;
				}
				# then its a key=value pair
				else
				{
					my $key = uc(shift(@parChunks));
					$param{$key} = join("=", @parChunks);
				}
			}
			
#			foreach my $key (keys %param)
#			{
#				print "ACTUALPARAMETER: $key=" . $param{$key} . "\n";
#			}
			
		}

		# if its a data line
		elsif ($line =~ m/^([^\*]*.*)$/)
		{
			my $thereIsAFollowLineAfterThisLine;
			
			# if its already a following line, then don't create a new entity
			if($dataLine == 0)
			{
				$entity = CAE::Abaqus::Abamod::Entity->new();
			}
			
			# a dangling ',' implies a followingLine to come after this one
			if($line =~ s/,$//)
			{
				$dataLine++;
				$thereIsAFollowLineAfterThisLine = 1;
			}
			else
			{
				$dataLine=0;
				$thereIsAFollowLineAfterThisLine = 0;
			}
			
			# data line 					
			my @line = split(",", $line);
			
			$entity->setStarkey($starkey);
			$entity->setParam($param);
			
			$entity->setComment([@starComment, @comment]);

			foreach(my $x=0, my $col=1+(8*$dataLine); $x<@line; $x++, $col++)
			{
				$entity->setCol($col, $line[$x]);
			}
			
			# if its the last line
			unless($thereIsAFollowLineAfterThisLine)
			{
				$self->addEntity($entity);
				undef(@comment);
			}
		}
	}
}

#---------------------
# hinzufuegen von entities
# addEntity(@Entity)
# return: -
#---------------------
sub addEntity
{
	my $self = shift;
	push @{$self->{'content'}}, @_;
}
#---------------------

#---------------------
# gibt ein objekt 'Abaqus' zurueck. filtert show oder noshow oder all und gibt das ergebnis ins show des neuen objektes zurueck.
# aufruf: filter($regex_abakey, \%param, \@data)
# Das Hash %param enthaelt alle Parameter, nach denen gefiltert werden soll. Angaben als Regular Expressions.
# Die Liste @data enthaelt die daten, nach denen gefiltert werden soll als Regular Expressions.
#---------------------
sub filter
{
	my $self = shift;

	my $filter_abakey = undef;
	if(@_) {$filter_abakey = shift;}

	my $refh_filter_param = undef;
	if(@_) {$refh_filter_param = shift;}
	
	my $refa_filter_data = undef;
	if(@_) {$refa_filter_data = shift;}

# ein neues objekt erzeugen
	my $filtered_model = CAE::Abaqus::Abamod->new();

	foreach my $obj (@{$self->{'content'}})
	{
		if ($obj->match($filter_abakey, $refh_filter_param, $refa_filter_data))
		{
			$filtered_model->addEntity($obj);
		}
	}
	return $filtered_model;
}

sub filter_shells
{
	my $self = shift;
	my $abamodel_shells = $self->filter("all", "element", {'type'=>'S3|S4'}, []);
	return $abamodel_shells;
}

sub filter_shells_of_nodes
{
	my $self = shift;
	my $nid = shift;
	my $abamodel_shells_of_node = Abaqus->new();

	my $abamodel_shells_of_node1 = $self->filter("all", "element", {'type'=>'S3|S4'}, [".+",$nid]);
	my $abamodel_shells_of_node2 = $self->filter("all", "element", {'type'=>'S3|S4'}, [".+",".+",$nid]);
	my $abamodel_shells_of_node3 = $self->filter("all", "element", {'type'=>'S3|S4'}, [".+",".+",".+",$nid]);
	my $abamodel_shells_of_node4 = $self->filter("all", "element", {'type'=>'S4'},    [".+",".+",".+",".+",$nid]);

	$abamodel_shells_of_node->merge($abamodel_shells_of_node1, $abamodel_shells_of_node2, $abamodel_shells_of_node3, $abamodel_shells_of_node4);

	return $abamodel_shells_of_node;
}

#---------------------
# merges models to this model
# merge(Nasmod, Nasmod, ...)
# return: -
#---------------------
sub merge
{
	my $self = shift;
	foreach my $model (@_)
	{
		push @{$self->{'content'}}, @{$model->{'content'}};
	}
}
#---------------------

#---------------------
# gets the entities that match the filter. if no filter is given, returns all entities
# getEntity(\@filter)
# return: @allEntitiesThatMatch
#---------------------
sub getEntity
{
	my $self = shift;

	# match ... filter ...
	return @{$self->{'content'}};
}
#---------------------

#---------------------
# gets the entities that match a certain ParamMd5
# getEntityByParamMd5($paramMd5)
# return: @allEntitiesThatMatch
#---------------------
sub getEntityByParamMd5
{
	my $self = shift;
	my $ParamMd5 = shift;
	my @matchedEntities;

	foreach my $entity ($self->getEntity())
	{
		if($entity->getParamMd5() eq $ParamMd5)
		{
			push(@matchedEntities, $entity);
		}
	}
	# match ... filter ...
	return @matchedEntities;
}
#---------------------

#---------------------
# count_entities
# count()
# return: int
#---------------------
sub count
{
	my $self = shift;
	return scalar( @{$self->{'content'}} );
}
#---------------------

#---------------------
# ermitteln von koordinaten eines knotens definiert durch eine node-id
sub koords_of_nid
{
	my $self = shift;
	my $nid = shift;
	
	my $abamodel_node_of_nid = $self->filter("all", "node", {}, [$nid]);
	my $refa_node = $abamodel_node_of_nid->getentities();
	
	return ${$refa_node}[0]->get_xyz;
}
#---------------------

#---------------------
# ermitteln von knoten-ids eines knotensets
sub nids_of_nset
{
	my $self = shift;
	my $nset = shift;
	
	my $abamodel_nset = $self->filter("all", "nset", {'nset' => $nset});
	
	my $refa_nset_entities = $abamodel_nset->getentities();
	
	my @nids;
	
	foreach my $nset_entity (@$refa_nset_entities)
	{
		push (@nids, $nset_entity->get_databits());
	} 
#	print "NIDS FROM NSET=$nset: *@nids*\n";
	return @nids;
}
#---------------------

#---------------------
# ermitteln der propertiynamen an einem knoten
# 1) ermitteln der shell-elemente an dem knoten
# 2) ermitteln jeweils des parameters 'ELSET' 
sub shellnames_at_nid
{
	my $self = shift;
	my $nid = shift;

    # alle angrenzenden shells herausfinden
	my $abamodel_shells_of_node = $self->filter_shells_of_nodes($nid);
	
	
	my @shellnames;

    # fuer jede shell den namen/propertynamen/ELSET= herausfinden
    # doppelte eintraege vermeiden
	foreach my $element (@{$abamodel_shells_of_node->getentities})
	{
		unless ( grep { $_ eq $element->get_name } @shellnames )
		{
			push(@shellnames, $element->get_name);
		}
	}
	return @shellnames;
}
#---------------------


#---------------------
# ermitteln der materialnamen an einem knoten
# 1) ermitteln des property-namens an dem knoten
# 2) ermitteln der 'MATERIAL' attributes in der Karte *SHELLSECTION 
sub matnames_at_nid
{
	my $self = shift;
	my $nid = shift;

	my @matnames;

	my @propertynames = $self->shellnames_at_nid($nid);
	
	foreach my $propertyname (@propertynames)
	{
#		print "propertyname is: $propertyname\n";
		my $submodel = $self->filter("all", "shell *section", {'elset'=>$propertyname});
#		$submodel->print_data();
		
		my $refa_shellsections = $submodel->getentities();
		
		foreach my $ent (@$refa_shellsections)
		{
			if ($ent->get_param('material'))
			{
#				print $ent->get_param('material') . "\n";
				push(@matnames, $ent->get_param('material'))
			}
		}
	}

	return @matnames;
}
#---------------------


#---------------------
# ermitteln des gemittelten (arithmetisch) einheits-normalen-vektors an angegebenen node id.
sub normale_at_nid
{
	my $self = shift;
	my $nid = shift;
	
	my $abamodel_shells_of_node = $self->filter_shells_of_nodes($nid);

	my @einheits_normalen_vektoren;

	my @all_x;
	my $summe_all_x;
	my @all_y;
	my $summe_all_y;
	my @all_z;
	my $summe_all_z;
	
	unless (@{$abamodel_shells_of_node->getentities})
	{
		return "ERROR: node with nid $nid not found.";
	}
	
	foreach my $element (@{$abamodel_shells_of_node->getentities})
	{
#		print "DEBUG: element: $element\n";

		my @nids;	#
		my %nids_koords;

		my $nid1 = $element->get_nid1;
		push @nids, $nid1;
		my $abamodel_node1 = $self->filter("all", "node", {}, [$nid1]);
		if ($abamodel_node1->countentities() == 0)
		{
			return "ERROR: node $nid1 not found in model. it is needed to calculate normale at element ".$element->get_eid().".\n";
		}
		my $refa_node1 = $abamodel_node1->getentities();
#		print "DEBUG: node: ${$refa_node1}[0]\n";
		my @node1_koord = ${$refa_node1}[0]->get_xyz();
		$nids_koords{$nid1} = \@node1_koord;

		my $nid2 = $element->get_nid2;
		push @nids, $nid2;
		my $abamodel_node2 = $self->filter("all", "node", {}, [$nid2]);
		if ($abamodel_node2->countentities() == 0)
		{
			return "ERROR: node $nid2 not found in model. it is needed to calculate normale at element ".$element->get_eid().".\n";
		}
		my $refa_node2 = $abamodel_node2->getentities();
#		print "DEBUG: node: ${$refa_node2}[0]\n";
		my @node2_koord = ${$refa_node2}[0]->get_xyz();
		$nids_koords{$nid2} = \@node2_koord;

		my $nid3 = $element->get_nid3;
		push @nids, $nid3;
		my $abamodel_node3 = $self->filter("all", "node", {}, [$nid3]);
		if ($abamodel_node3->countentities() == 0)
		{
			return "ERROR: node $nid3 not found in model. it is needed to calculate normale at element ".$element->get_eid().".\n";
		}
		my $refa_node3 = $abamodel_node3->getentities();
#		print "DEBUG: node: ${$refa_node3}[0]\n";
		my @node3_koord = ${$refa_node3}[0]->get_xyz();
		$nids_koords{$nid3} = \@node3_koord;

		if ($element->get_nid4)
		{
			my $nid4 = $element->get_nid4;
			push @nids, $nid4;
			my $abamodel_node4 = $self->filter("all", "node", {}, [$nid4]);
			my $refa_node4 = $abamodel_node4->getentities();
#			print "DEBUG: node: ${$refa_node4}[0]\n";
			my @node4_koord = ${$refa_node4}[0]->get_xyz();
			$nids_koords{$nid4} = \@node4_koord;
		}

		my @nids_sortiert;
# feststellen an welcher stelle die nid vorkommt, ueber die die position des normalenvektors definiert wurde.
		for(my $x=0; $x < (scalar @nids); $x++)
		{
			if ($nids[$x] == $nid)
			{
#				push @nids_sortiert, $nids[$x];
				if ($x == 0)   { push @nids_sortiert, @nids }
				elsif($x == 1) { push @nids_sortiert, @nids[1..$#nids], $nids[0] }
				elsif($x == 2) { push @nids_sortiert, @nids[2..$#nids], $nids[0], $nids[1] }
				elsif($x == 3) { push @nids_sortiert, $nids[3], $nids[0], $nids[1] , $nids[2]}
			}
		}
#		print "DEBUG: unsorted ids: @nids\n";
#		print "DEBUG: sorted ids:   @nids_sortiert\n";

		my @einheits_normalen_vector = &normale_einer_ebene(@{$nids_koords{$nids_sortiert[0]}}, @{$nids_koords{$nids_sortiert[1]}}, @{$nids_koords{$nids_sortiert[2]}});
		push @einheits_normalen_vektoren, \@einheits_normalen_vector;
		$summe_all_x += $einheits_normalen_vector[0];
		$summe_all_y += $einheits_normalen_vector[1];
		$summe_all_z += $einheits_normalen_vector[2];
		push @all_x, $einheits_normalen_vector[0];
		push @all_y, $einheits_normalen_vector[1];
		push @all_z, $einheits_normalen_vector[2];
	}

	my @gemittelter_einheits_normalen_vektor;

	$gemittelter_einheits_normalen_vektor[0] = $summe_all_x / (scalar(@all_x));
	$gemittelter_einheits_normalen_vektor[1] = $summe_all_y / (scalar(@all_y));
	$gemittelter_einheits_normalen_vektor[2] = $summe_all_z / (scalar(@all_z));

	return @gemittelter_einheits_normalen_vektor;
}



1;

__END__

=head1 NAME

CAE::Abaqus::Abamod - basic access to abaqus models

=head1 SYNOPSIS

    use CAE::Abaqus::Abamod;

    # create object of a abaqus model
    my $model = CAE::Abaqus::Abamod->new();

    # import content from a nastran file
    $model->importData("file.inc");

    # filter for *ELEMENT of TYPE S4 or S3 and on second column a 100
    my $model2 = $model->filter("ELEMENT", {"TYPE" => ["S4", "S3"]}, ["", "100"]);

    # print to a file
    $model2->print("file.nas");

=head1 DESCRIPTION

import a abaqus model from files, filter content, extract data, overwrite data, write content to file.

=head1 API

=head2 new()

creates and returns a new and empty nastran model

    # create a new Abamod
    my $model = CAE::Abaqus::Abamod->new();

=head2 importBulk()

imports a Abaqus model from file.

    # define options and filter
    my %OPTIONS = (
        cards => ["GRID", "CTRIA"],         # fastest way to reduce data while importing. only mentioned cardnames will be imported. the values in 'cards' match
                                            # always without a trailing anchor => "CTRIA" matches "CTRIA3" and "CTRIA6"
        filter => ["", "", 10],             # only the content passing this filter will be imported. same dataformat as in filter().
        maxoccur => 5                       # stops the import if this amount of entities has been imported.
    )

    # create object of a nastran model
    my $model = CAE::Nastran::Nasmod->new();
    
    # adds all bulk data of a file
    $model->importBulk("file.inc");
    
    # adds only the bulk data of the file, that passes the filter
    $model->importBulk("file2.inc", \%OPTIONS);

=head2 filter()

returns a new Nasmod with only the entities that pass the whole filter. A filter is an array of regexes. $filter[0] is the regex for the comment, $filter[1] is the regex for column 1 of the nastran card, $filter[2] is the regex for column 2 ... A nastran card passes the filter if every filter-entry matches the correspondent column or comment. Everything passes an empty filter-entry. The filter-entry for the comment matches without anchors. filter-entries for data columns will always match with anchors (^$). A filter-entry may be an array with alternatives - in this case only one alternative has to match.

    # filter for GRID (NID=1000)
    my @filter = (
        "",                   # pos 0 filters comment:  entities pass which match // in the comment. (comment => no anchors in the regex)
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1. (note the anchors in the regex)
        "1000"                # pos 2 filters column 2: entities pass which match /^1000$/ in column 2. (note the anchors in the regex)
        ""                    # pos 3 filters column 3: entities pass which match // in column 3. (empty => no anchors in the regex)
    )

    my $filteredModel = $model->filter(\@filter);

    # filter for GRIDs (999 < NID < 2000)
    my @filter2 = (
        "lulu",               # pos 0 filters comment:  only entities pass which match /lulu/ somewhere in the comment (comment = no anchors in the regex)
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1.
        "1\d\d\d"             # pos 2 filters column 2: entities pass which match /^1\d\d\d$/ in column 2.
    )

    my $filteredModel2 = $model->filter(\@filter2);

    # filter for GRIDs ( (999 < NID < 2000) and (49999 < NID < 60000) and (69999 < NID < 80000))
    my @filter3 = (
        "",                   # pos 0 filters comment:  all entities match empty filter
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1.
        [
            "1\d\d\d",        # pos 2 filters column 2: entities pass which match /^1\d\d\d$/ in column 2.
            "5\d\d\d\d",      # pos 2 filters column 2: or which match /^5\d\d\d\d$/ in column 2.
            "7\d\d\d\d"       # pos 2 filters column 2: or which match /^7\d\d\d\d$/ in column 2.
        ]
    )

    my $filteredModel3 = $model->filter(\@filter3);

=head2 getEntity()

returns all entities or only entities that pass a filter.

    my @allEntities = $model->getEntitiy();

    my @certainEntities = $model->getEntity(\@filter);

=head2 addEntity()

adds entities to a model.

    # create new Entities
    my $entity = CAE::Nastran::Nasmod::Entity->new();

    $entity->setComment("just a test"); # comment
    $entity->setCol(1, "GRID");         # column 1: cardname
    $entity->setCol(2, 1000);           # column 2: id
    $entity->setCol(4, 17);             # column 4: x
    $entity->setCol(5, 120);            # column 5: y
    $entity->setCol(6, 88);             # column 6: z

    my $entity2 = CAE::Nastran::Nasmod::Entity->new(); 
    $entity2->setComment("another test", "this is the second line of the comment");
    $entity2->setCol(1, "GRID");
    $entity2->setCol(2, 1001);
    $entity2->setCol(4, 203);
    $entity2->setCol(5, 77);
    $entity2->setCol(6, 87);

    # adds the entities to the model
    $model->addEntity($entity, $entity2);

=head2 merge()

merges two models.

    $model1->merge($model2);    # $model2 is beeing merged into model1

=head2 getCol()

returns the desired column of every entity in the model as an array.

    my $model2 = $model->filter(["", "GRID"]);     # returns a Nastranmodel $model2 that contains only the GRIDs of $model
    my @col2   = $model2->getCol(2);               # returns an array with all GRID-IDs (column 2) of $model2

=head2 count()

returns the amount of all entities stored in the model

    $model1->count();

=head2 print()

prints the whole model in nastran format to STDOUT or to a file.

    $model->print();              # prints to STDOUT
    $model->print("file.nas");    # prints to file.nas

=head1 LIMITATIONS

only bulk data is supported. only 8-field nastran format is supported. the larger the model, the slowlier is filtering.

=head1 TODO

indexing to accelerate filtering

=head1 TAGS

CA, CAE, FEA, FEM, Nastran, perl, Finite Elements, CAE Automation, CAE Automatisierung

=head1 AUTHOR

Alexander Vogel <avoge@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2014, Alexander Vogel, All Rights Reserved.
You may redistribute this under the same terms as Perl itself.
