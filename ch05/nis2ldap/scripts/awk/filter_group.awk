# -*- awk -*-
#
# filter nis group
# awk -f quicksort.awk -f filter_group.awk nis.group maingroup.$timestamp
BEGIN{
    FS=":";
    group_number = 0;
    delete gids;
    delete idxs;
    delete groups;
    delete members;
}
/^ *$/ { next; }
/^#/   { next; }
{
    if( FILENAME ~ /maingroup/ ){
	i = index($0, ",");
	gid = substr($0,1,i-1);
	uids = substr($0,i+1);
	if( gid in members ){
	    members[ gid ] = members[ gid ] "," uids;
	}else{
	    j = index(uids, ",");
	    if( j > 0 ){
		tmpgnm = substr(uids, 1, j-1);
	    }else{
		tmpgnm = uids;
	    }
	    printf "[WARNING] GID(%d) to which User \"%s\" belongs does not exist in NIS Group\n", gid, tmpgnm > "/dev/stderr"; 
	    # printf "[WARNING] Add GID(%d) as \"%s\"\n", gid, tmpgnm > "/dev/stderr";
	    gids[ ++group_number ] = gid;
	    idxs[ group_number ] = group_number;
	    groups[ gid ] = tmpgnm;
	    members[ gid ] = uids;
	}
    }else{
	if( length($1) > 0 ){
	    gids[ ++group_number ] = $3;
	    idxs[ group_number ] = group_number;
	    groups[ $3 ] = $1;
	    members[ $3 ] = $4;
	}
    }
}
END{
    quicksort_cmpint(idxs, gids, 1, group_number);
    for( i = 1; i <= group_number ; ++i ){
        gid = gids[ idxs[i] ];
	gnm = groups[ gid ];
	ml = split( members[ gid ], tmp, "," );

	delete exists;
	delete mems;
	delete midx;
	mnum = 0;
	for( j = 1; j <= ml ; ++j ){
	    mnm = tmp[j];
	    if( !(mnm in exists) ){
		exists[ mnm ] = 1;
		++mnum;
		midx[ mnum ] = mnum;
		mems[ mnum ] = mnm;
	    }
	}

	quicksort(midx, mems, 1, mnum);
	memstr = mems[ midx[1] ];
	for( j = 2; j <= mnum ; ++j ){
	    memstr = memstr "," mems[ midx[j] ];
	}
	printf("%s:x:%s:%s\n", gnm, gid, memstr );
    }
}
