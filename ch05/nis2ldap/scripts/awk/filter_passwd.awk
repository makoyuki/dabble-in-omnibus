# -*- awk -*-
#
# filter nis master.passwd
#
# awk -v ldifdir=xxxx -f filter_passwd.awk master.passwd TS=${TIMESTAMP}
BEGIN{
    if( ldifdir != "" ){
	l = length( ldifdir );
	if ( substr(ldifdir,l,1) != "/" ){
	    ldifdir = ldifdir "/";
	}
    }
    
    FS=":";
    user_number = 0;
    delete uids;
    delete users;
    delete groups;

}
/^ *$/ { next; }
/^#/   { next; }
{
    uids[ ++user_number ] = $3;
    idxs[ user_number ] = user_number;
    if( ($4 == 10) || ($4 == 20) ){
	users[ $3 ] = sprintf("%s:*:%d:%d::0:%d:%s:%s:%s", $1, $3, 513, $7, $8, $9, $10);
	groups[ $4 ] = groups[ $4 ] "," $1;
    }else{
	users[ $3 ] = sprintf("%s:*:%d:%d::0:%d:%s:%s:%s", $1, $3, $4, $7, $8, $9, $10);
	groups[ $4 ] = groups[ $4 ] "," $1;
    }	
}
END{
    quicksort_cmpint(idxs, uids, 1, user_number);
    for( i = 1; i <= user_number ; ++i ){
        uid = uids[ idxs[i] ];
	if( uid >= 1000 ){
	    printf("%s\n", users[ uid ]);
	}
    }

    MAINGROUP = ldifdir "maingroup." TS ;
    for( gid in groups ){
	printf "%s%s\n", gid, groups[gid] >> MAINGROUP;
    }
}
