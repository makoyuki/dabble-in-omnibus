# -*- mode:awk -*-
# 
# diff group.before group.after | awk -v ldifdir=xxxx -v TS=yyyymmdd-HHMMSS -f group_diff2ldif.awk \
# BASEDN="dc=example,dc=co,dc=jp" SID=$sambaSID GID=$sambaNextGroupRid BASE=$sambaAlgorithmicRidBase
BEGIN{
    if( ldifdir != "" ){
	l = length( ldifdir );
	if ( substr(ldifdir,l,1) != "/" ){
	    ldifdir = ldifdir "/";
	}
    }
    
    DEL_GROUP = ldifdir "del_group." TS;
    MOD_GROUP = ldifdir "mod_group." TS ".ldif";
    ADD_GROUP = ldifdir "add_group." TS ".ldif";
    NEXT_GROUP_RID = ldifdir "sambaNextGroupRid." TS ".txt";
    
    n = 0;
}

function add_group(line,  group, gidNumber, members, i, mn, retv, exists){
    l = split(line, field, ":");
    group = field[1];
    gidNumber = field[3];
    
    delete exists
    retv = sprintf("dn: cn=%s,ou=Group,%s\n", group, BASEDN);
    retv = retv sprintf("objectClass: top\n");
    retv = retv sprintf("objectClass: posixGroup\n");
    retv = retv sprintf("cn: %s\n", group);
    retv = retv sprintf("gidNumber: %d\n", gidNumber);
    if( field[4] != "" ){
	mn=split(field[4], members, ",");
	for(i=1;i<=mn;++i){
	    if( (members[i] != "") && (!(members[i] in exists)) ){
		retv = retv sprintf("memberUid: %s\n", members[i]);
		exists[members[i]] = 1;
	    }
	}
    }
    return retv;
}

function add_samba_group(line, grid,      group, gidNumber, members, i, mn, retv, rid, exists){
    l = split(line, field, ":");
    group = field[1];
    gidNumber = field[3];

    delete exists
    retv = sprintf("dn: cn=%s,ou=Group,%s\n", group, BASEDN);
    retv = retv sprintf("objectClass: top\n");
    retv = retv sprintf("objectClass: posixGroup\n");
    retv = retv sprintf("objectClass: sambaGroupMapping\n");
    retv = retv sprintf("cn: %s\n", group);
    retv = retv sprintf("gidNumber: %d\n", gidNumber);

    rid = 2 * grid + BASE + 1;
    retv = retv sprintf("sambaSID: %s-%d\n", SID, rid );
    retv = retv sprintf("sambaGroupType: 5\n");
    if( field[4] != "" ){
	mn=split(field[4], members, ",");
	for(i=1;i<=mn;++i){
	    if( (members[i] != "") && (!(members[i] in exists)) ){
		retv = retv sprintf("memberUid: %s\n", members[i]);
		exists[members[i]] = 1;
	    }
	}
    }
    return retv;
}

function modify_group(b,a,   before, after, retv, i, mn, sep, members){
    split(b, before, ":");
    split(a, after , ":");
    
    retv = retv sprintf("dn: cn=%s,ou=Group,%s\n", after[1], BASEDN);
    retv = retv sprintf("changetype: modify\n");
    sep  = ""
    if( before[3] != after[3] ){
	retv = retv sep sprintf("replace: gidNumber\n");
        retv = retv sprintf("gidNumber: %d\n", after[3]);
	sep = "-\n";
    }
    if( before[4] != after[4] ){
	if( after[4] == "" ){
	    retv = retv sep sprintf("delete: memberUid\n");
	}else{
	    retv = retv sep sprintf("replace: memberUid\n");
	    mn = split(after[4], members, ",");
	    for( i = 1 ; i <= mn ; ++i ){
		retv = retv sprintf("memberUid: %s\n", members[i]);
	    }
	}
	retv = retv "\n";
    }
    return retv;
}

/^</ {
    line = substr($0, 3);
    l = split(line, field, ":");
    group = field[1];
    group_counter[group] += 1;
    before[ group ] = line;
}
/^>/ {
    line = substr($0, 3);
    if( substr(line, 1, 1) == "#" ){
	next;
    }
    l = split(line, field, ":");
    group = field[1];
    group_counter[group] -= 1;
    if( !(group in lines) ){
	++n;
	order[n] = group;
    }
    lines[ group ] = line;
}
END{
    d_first = 1;
    m_first = 1;
    a_first = 1;
    m_sep = "";
    a_sep = "";
    grid = GID;
    
    for( group in group_counter ){
	count = group_counter[group];
	if( count > 0 ){
	    # delete
	    if( d_first ){
		printf "" > DEL_GROUP;
		d_first = 0;
	    }
	    printf "cn=%s,ou=Group,%s\n", group,BASEDN >> DEL_GROUP;
	}
    }
    
    for( i = 1; i <= n ; ++i ){
	group = order[i];
	count = group_counter[ group ];
	if( count == 0 ){
	    # modify
	    if( m_first ){
		printf "" > MOD_GROUP;
		m_first = 0;
	    }
	    printf "%s%s", m_sep, modify_group( before[ group ], lines[ group ] ) >> MOD_GROUP;
	}else if( count < 0 ){
	    # add
	    if( a_first ){
		printf "" > ADD_GROUP;
		a_first = 0;
	    }
	    if( grid > 0 ){
		++grid;
		printf "%s%s", a_sep, add_samba_group( lines[ group ], grid ) >> ADD_GROUP;
	    }else{
		printf "%s%s", a_sep, add_group( lines[ group ] ) >> ADD_GROUP;
	    }
	    a_sep = "\n";
	}
    }

    printf "%d", grid > NEXT_GROUP_RID;
}
