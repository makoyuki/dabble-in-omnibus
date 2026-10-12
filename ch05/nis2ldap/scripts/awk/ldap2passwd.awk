# -*- awk -*-
#
# nis master.passwd
# 1    2      3   4   5 6 7 8     9    10
# user:passwd:uid:gid:?:0:0:gecos:home:shell
# field 5: User's login class.
# field 6: Password change time.
# field 7: Account expiration time.
#
# except: uid < 1000
function register_user(){
    if( user == "testuser" ){
	return;
    }
    uids[ ++user_number ] = uid;
    idxs[ user_number ] = user_number;
    users[ uid ] = sprintf("%s:*:%d:%d::0:%d:%s:%s:%s", user, uid, gid, expire, gecos, homedir, shell );
    
    uid     = "";
    gid     = "";
    expire  = 0;
    gecos   = "";
    homedir = "";
    shell   = "";
}
BEGIN{
    srand(0);
    FS=":";
    user = "";
    user_number = 0;
    delete uids;
    delete users;
}
/^#/{
    next;
}
/^ *$/ {
    next;
}
/^dn\: *uid=/ {
    if( user != "" ){
	register_user();
    }
    i = index($2, "=");
    l = substr($2, i+1);
    j = index(l, ",");
    
    user = substr(l, 1, j-1);
    next;
}
/^uidNumber\:/ {
    gsub("^ *", "", $2);
    uid = $2;
}
/^gidNumber\:/ {
    gsub("^ *", "", $2);
    gid = $2;
}
/^shadowExpire\:/ {
    gsub("^ *", "", $2);
    expire = $2;
}
/^description\:/ {
    gsub("^ *", "", $2);
    gecos = $2;
}
/^homeDirectory\:/ {
    gsub("^ *", "", $2);
    homedir = $2;
}
/^loginShell\:/ {
    gsub("^ *", "", $2);
    shell = $2;
}
END{
    register_user();
    quicksort_cmpint(idxs, uids, 1, user_number);
    for( i = 1; i <= user_number ; ++i ){
	uid = uids[ idxs[i] ];
	if( uid >= 1000 ){
	printf("%s\n", users[ uid ]);
	}
    }
}
