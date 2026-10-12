# -*- awk -*-
#
# nis group
# 1    2      3   4
# group:passwd:gid:member1,member2,...
# 
function register(){
    gids[ ++group_number ] = gidNumber;
    idxs[ group_number ] = group_number;
    
    groups[ gidNumber ] = sprintf("%s:x:%d:%s", group, gidNumber, members);
   
    group = "";
    gidNumber = "";
    members = "";
}
BEGIN{
    srand(0);
    FS=":";
    group = "";
    group_number = 0;
    delete groups;
    delete gids;
    delete idxs;
}
/^#/{
    next;
}
/^ *$/ {
    next;
}
/^dn\: *cn=/ {
    if( group != "" ){
	if( sambaGroupType != 2 ){
	    register();
	}
    }
    msep = "";
    sambaGroupType = "";
}
/^cn\:/ {
    gsub("^ *", "", $2);
    group = $2;
}
/^gidNumber\:/ {
    gsub("^ *", "", $2);
    gidNumber = $2;
}
/^memberUid\:/ {
    gsub("^ *", "", $2);
    members = members msep $2;
    msep = ",";
}
/^sambaGroupType\:/ {
    gsub("^ *", "", $2);
    sambaGroupType = $2;
}
END{
    if( group != "" ){
	if( sambaGroupType != 2 ){
	    register();
	}
    }
    if( group_number > 0 ){
	quicksort_cmpint(idxs, gids, 1, group_number);
	
	for( i = 1; i <= group_number ; ++i ){
	    gid = gids[ idxs[i] ];
	    printf("%s\n", groups[ gid ]);
	}
    }
}
