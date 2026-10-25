# -*- bash -*-
if [ "x${DEFINE}" == "x" ]
then
    export DEFINE=True
   
    # LDAP settgings
    export BASEDN="dc=example,dc=jp"
    export sambaDomain=ldapserver名
    export manager="cn=Manager"
    export admin="cn=admin"
    
    # directory path
    export OPENLDAPDIR=/usr/local/etc/openldap
    export SCRIPTSDIR=${OPENLDAPDIR}/scripts
    export AWKDIR=${SCRIPTSDIR}/awk
    export TMPDIR=${SCRIPTSDIR}/tmp
    export LDIFDIR="${OPENLDAPDIR}/settings/$( date +%Y-%0m )"
    export LDAPGROUP=${OPENLDAPDIR}/ldapgroups/group
    export TIMESTAMP=$( date +%Y%0m%0d-%0H%0M%0S )

    if [ ! -d "${TMPDIR}" ]
    then
	echo "mkdir ${TMPDIR}"
	mkdir -p "${TMPDIR}"
    fi
    
    if [ ! -d "${LDIFDIR}" ]
    then
	echo "mkdir ${LDIFDIR}"
	mkdir -p "${LDIFDIR}"
	if [ $? -ne 0 ]
	then
	    exit 1
	fi
    fi
fi
# samba 
declare -A sambaParam
for l in $( ldapsearch -Y EXTERNAL -H ldapi:// -LLL -b "${BASEDN}" "(& (objectClass=sambaDomain)(sambaDomainName=${sambaDomain}))" | awk '
/^#/{ next ; }
/^ *$/ { next; }
{
    i = index($0, ": ");
    key=substr($0,1,i-1);
    val=substr($0,i+2);
    printf "%s:%s\n", key,val;
}' )    
do
    key="${l%%\:*}"
    val="${l#*\:}"
    sambaParam["${key}"]="${val}"
done
