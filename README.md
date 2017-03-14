# NAME

CAE::Abaqus::Abamod - basic access to abaqus models

# SYNOPSIS

    use CAE::Abaqus::Abamod;

    # create object of a abaqus model
    my $model = CAE::Abaqus::Abamod->new();

    # import content from a nastran file
    $model->importData("file.inc");

    # filter for *ELEMENT of TYPE S4 or S3 and on second column a 100
    my $model2 = $model->filter("ELEMENT", {"TYPE" => ["S4", "S3"]}, ["", "100"]);

    # print to a file
    $model2->print("file.nas");

# DESCRIPTION

import a nastran model from files, filter content, extract data, overwrite data, write content to file.

# API

## new()

creates and returns a new and empty nastran model

    # create a new Nasmod
    my $model = CAE::Nastran::Nasmod->new();

## importBulk()

imports a Nastran model from file. it only imports nastran bulk data. no sanity checks will be performed - duplicate ids or the like are possible.

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

## filter()

returns a new Nasmod with only the entities that pass the whole filter. A filter is an array of regexes. $filter\[0\] is the regex for the comment, $filter\[1\] is the regex for column 1 of the nastran card, $filter\[2\] is the regex for column 2 ... A nastran card passes the filter if every filter-entry matches the correspondent column or comment. Everything passes an empty filter-entry. The filter-entry for the comment matches without anchors. filter-entries for data columns will always match with anchors (^$). A filter-entry may be an array with alternatives - in this case only one alternative has to match.

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

## getEntity()

returns all entities or only entities that pass a filter.

    my @allEntities = $model->getEntitiy();

    my @certainEntities = $model->getEntity(\@filter);

## addEntity()

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

## merge()

merges two models.

    $model1->merge($model2);    # $model2 is beeing merged into model1

## getCol()

returns the desired column of every entity in the model as an array.

    my $model2 = $model->filter(["", "GRID"]);     # returns a Nastranmodel $model2 that contains only the GRIDs of $model
    my @col2   = $model2->getCol(2);               # returns an array with all GRID-IDs (column 2) of $model2

## count()

returns the amount of all entities stored in the model

    $model1->count();

## print()

prints the whole model in nastran format to STDOUT or to a file.

    $model->print();              # prints to STDOUT
    $model->print("file.nas");    # prints to file.nas

# LIMITATIONS

only bulk data is supported. only 8-field nastran format is supported. the larger the model, the slowlier is filtering.

# TODO

indexing to accelerate filtering

# TAGS

CA, CAE, FEA, FEM, Nastran, perl, Finite Elements, CAE Automation, CAE Automatisierung

# AUTHOR

Alexander Vogel <avoge@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2012-2014, Alexander Vogel, All Rights Reserved.
You may redistribute this under the same terms as Perl itself.
