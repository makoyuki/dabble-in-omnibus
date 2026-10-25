# -*- awk -*-
#
# diff passwd.before passwd.after | \
# gawk -v ldifdir=xxxx -v TS=yyyymmdd-HHMMSS -v master=master.passwd \
#      -f diff2ldif.awk BASEDN="dc=example,dc=co,dc=jp" SID=$sambaSID \
#      SDN=$sambaDomainName NBN=$NetBiosName BASE=$sambaAlgorithmicRidBase UID=$sambaNextUserRid
#  -> { del_users, mod_users.ldif, add_users.ldif, sambaNextUserRid.txt }
BEGIN{
    if( ldifdir != "" ){
        l = length( ldifdir );
        if ( substr(ldifdir,l,1) != "/" ){
            ldifdir = ldifdir "/";
        }
    }

    delete user2passwd;
    if( master != "" ){
        while( (getline line < master ) == 1 ){
            if( (!( line ~ /^#/ )) && (!( line ~ /^ *$/)) ){
                n = split(line, field, ":");
                user2passwd[field[1]] = field[2];
            }
        }
    }

    DEL_USERS = ldifdir "del_users." TS;
    MOD_USERS = ldifdir "mod_users." TS ".ldif";
    ADD_USERS = ldifdir "add_users." TS ".ldif";
    NEXT_UID  = ldifdir "sambaNextUserRid." TS ".txt" ;

    mod_array[ 2] = "userPassword" ;
    mod_array[ 3] = "uidNumber"    ;
    mod_array[ 4] = "gidNumber"    ;
    mod_array[ 5] = "class"        ; # no use
    mod_array[ 6] = "change"       ; # no use
    mod_array[ 7] = "shadowExpire" ;
    mod_array[ 8] = "description"  ;
    mod_array[ 9] = "homeDirectory";
    mod_array[10] = "loginshell"   ;

    n = 0;
}
function add_uid(line,     i, l, field, uid, retv, sur_name, first_name, display_name, comment, passwd){
    l = split(line, field, ":");
    for( i = 1; i <= l ; ++i ){
        sub("^ *","",field[i]);
        sub(" *$","",field[i]);
    }
    # uid       = field[ 1];
    # crypt     = field[ 2];
    # uidNumber = field[ 3];
    # gidNumber = field[ 4];
    # change    = field[ 6];
    # expire    = field[ 7];
    # comment   = field[ 8];
    # home      = field[ 9];
    # shell     = field[10];

    uid = field[1];
    passwd = "";
    if( field[9] ~ /\/prj/ ){
        sur_name     = field[1];
        first_name   = field[1];
        display_name = field[1];
        comment      = field[8];
    }else{
        i = index( field[8], " " );
        if( i == 0 ){
            sur_name    = uid;
            first_name  = uid;
            display_name = uid;
            comment     = field[8];
        }else{
            sur_name     = substr( field[8], 1, i - 1);
            first_name   = substr( field[8], i + 1 );
            display_name = field[8];
            comment = field[8];
        }
        if( uid in user2passwd ){
            passwd = user2passwd[uid];
        }
    }

    retv = sprintf( "dn: uid=%s,ou=People,%s\n", uid, BASEDN );
    retv = retv sprintf( "objectClass: top\n" );
    retv = retv sprintf( "objectClass: inetOrgPerson\n"   );
    retv = retv sprintf( "objectClass: posixAccount\n"    );
    retv = retv sprintf( "objectClass: shadowAccount\n"   );
    retv = retv sprintf( "objectClass: sambaSamAccount\n" );
    retv = retv sprintf( "uid: %s\n"          , uid       );
    retv = retv sprintf( "cn: %s\n"           , uid       );
    retv = retv sprintf( "sn: %s\n"           , sur_name     );
    retv = retv sprintf( "givenName: %s\n"    , first_name   );
    retv = retv sprintf( "displayName: %s\n"  , display_name );
    retv = retv sprintf( "uidNumber: %d\n"    , field[ 3]    );
    retv = retv sprintf( "gidNumber: %d\n"    , field[ 4]    );
    retv = retv sprintf( "homeDirectory: %s\n", field[ 9]    );
    retv = retv sprintf( "loginshell: %s\n"   , field[10]    );

    if( passwd != "" ){
        retv = retv sprintf( "userPassword: {CRYPT}%s\n", passwd );
    }
    if( comment != "" ){
        retv = retv sprintf( "description: %s\n", comment );
    }
    if( field[7] > 0 ){
        retv = retv sprintf( "shadowExpire: %s\n", field[7] );
    }

    ++UID;
    RID=2*UID+BASE;

    retv = retv sprintf( "sambaSID: %s-%s\n"  , SID, RID);
    retv = retv sprintf( "sambaPrimaryGroupSID: %s-513\n"  , SID );
    retv = retv sprintf( "sambaAcctFlags: [U          ]\n" );
    retv = retv sprintf( "sambaDomainName: %s\n", SDN );
    retv = retv sprintf( "sambaHomePath: \\\\%s\\%s\n", NBN, uid );
    retv = retv sprintf( "sambaProfilePath: \\\\%s\\%s\\profile\n", NBN, uid );

    return retv;
}

function modify_uid(b, a,     before, after, i, retv, mod_type, command, sep){
    split(b, before, ":");
    split(a, after , ":");
    # uid       = field[ 1];
    # crypt     = field[ 2];
    # uidNumber = field[ 3];
    # gidNumber = field[ 4];
    # change    = field[ 6];
    # expire    = field[ 7];
    # comment   = field[ 8];
    # home      = field[ 9];
    # shell     = field[10];

    retv = sprintf("dn: uid=%s,ou=People,%s\n", after[1], BASEDN);
    retv = retv sprintf("changetype: modify\n");

    sep      = "";
    for( i = 2 ; i <= 10 ; ++i ){
        mod_type = "";
        command  = "";
        if( before[i] != after[i] ){
            if( i == 2 ){
                # userPassword
                continue;
            }else if( i == 7 ){ # shadowExpire
                if( before[i] == 0 ){
                    mod_type = "add";
                    command  = sprintf("%s: %s\n", mod_array[i], after[i]);
                }else if( after[i] == 0 ){
                    mod_type = "delete";
                }else{
                    mod_type = "replace";
                    command  = sprintf("%s: %s\n", mod_array[i], after[i]);
                }
            }else{
                mod_type = "replace";
                command  = sprintf("%s: %s\n", mod_array[i], after[i]);
            }

            retv = retv sprintf("%s%s: %s\n%s", sep, mod_type, mod_array[i], command);
            sep = "-\n";
        }
    }

    return retv;
}
/^</ {
    line = substr($0, 3);
    l = split(line, field, ":");
    uid = field[1];
    uid_counter[uid] += 1;
    before[ uid ] = line;
}
/^>/ {
    line = substr($0, 3);
    if( line ~ /^#/ ){
        # retired
        next;
    }
    l = split(line, field, ":");
    uid = field[1];
    uid_counter[uid] -= 1;

    if( !(uid in lines) ){
        ++n;
        order[n] = uid;
    }
    lines[uid] = line;
}
END{
    d_first = 1;
    m_first = 1;
    a_first = 1;
    m_sep   = "";
    a_sep   = "";

    for( uid in uid_counter ){
        count = uid_counter[uid];
        if( count > 0 ){
            # retired : delete
            if( d_first ){
                printf "" > DEL_USERS;
                d_first = 0;
            }
            printf "uid=%s,ou=People,%s\n", uid,BASEDN >> DEL_USERS;
        }
    }
    for( i = 1; i <= n ; ++i ){
        uid = order[i];
        count = uid_counter[ uid ];
        if( count == 0 ){
            # modify
            if( m_first ){
                printf "" > MOD_USERS;
                m_first = 0;
            }
            printf "%s%s", m_sep, modify_uid( before[uid], lines[uid] ) >> MOD_USERS;
            m_sep = "\n";
        }else if( count < 0 ){
            # add
            if( a_first ){
                printf "" > ADD_USERS;
                a_first = 0;
            }
            printf "%s%s", a_sep, add_uid( lines[uid] ) >> ADD_USERS;
            a_sep = "\n";
        }
    }

    printf "%d", UID >> NEXT_UID;
}
