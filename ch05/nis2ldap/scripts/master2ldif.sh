#!/bin/bash
function HELP(){
    printf "master2ldif master.passwd\n"
}

#
# start
# 
SCRIPTSDIR=/usr/local/etc/openldap/scripts
PARAM="${SCRIPTSDIR}/ldap_params.sh"
if [ ! -f "${PARAM}" ]
then
    echo "Fatal Error!" >&2
    exit 1
fi
. "${PARAM}"
echo TIMESTAMP=${TIMESTAMP}
PASSWD_BAK="${TMPDIR}/old_passwd.$$"
PASSWD_NIS="${TMPDIR}/new_passwd.$$"

function remove_tmps(){
    rm -f "${PASSWD_BAK}" "${PASSWD_NIS}"
}

# input modified master.passwd
if [ $# -eq 0 ]
then
    HELP 
    exit 1
fi
PASSWD="${1}"
if [ ! -f "${PASSWD}" ]
then
    exit 1
fi

for f in \
ldap2passwd.awk \
filter_passwd.awk \
quicksort.awk \
diff2ldif.awk
do
    if [ ! -f "${AWKDIR}/${f}" ]
    then
	# environment error
	exit 128
    fi
done

ldapsearch -Y EXTERNAL -H ldapi:// -LLL -b "ou=People,${BASEDN}" uid=\* | awk -f "${AWKDIR}/quicksort.awk" -f "${AWKDIR}/ldap2passwd.awk" > "${PASSWD_BAK}"
ldapstatus=${PIPESTATUS[0]}
if [ $ldapstatus -ne 0 ]
then
    remove_tmps
    exit 1
fi
NetBiosName=$( uname -n | sed 's/\..*//' | tr a-z A-Z )

awk -v "ldifdir=${LDIFDIR}" -f "${AWKDIR}/quicksort.awk" -f "${AWKDIR}/filter_passwd.awk" "${PASSWD}" "TS=${TIMESTAMP}" > "${PASSWD_NIS}"
diff "${PASSWD_BAK}" "${PASSWD_NIS}" | awk -v "ldifdir=${LDIFDIR}" -v "TS=${TIMESTAMP}" -v "master=${PASSWD}"  -f "${AWKDIR}/diff2ldif.awk" "BASEDN=${BASEDN}" "SID=${sambaParam[sambaSID]}" "SDN=${sambaParam[sambaDomainName]}" "NBN=$NetBiosName" "BASE=${sambaParam[sambaAlgorithmicRidBase]}" "UID=${sambaParam[sambaNextUserRid]}"
remove_tmps
