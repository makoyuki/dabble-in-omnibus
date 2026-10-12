#!/bin/bash
function HELP(){
    printf "group2ldif group\n"
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

for f in \
ldap2group.awk \
filter_group.awk \
quicksort.awk \
group_diff2ldif.awk
do
    if [ ! -f "${AWKDIR}/${f}" ]
    then
	echo "Fatal Error!" >&2
	exit 1
    fi
done

GROUP_BAK="${TMPDIR}/old_group.$$"
GROUP_NIS="${TMPDIR}/new_group.$$"
function remove_tmps() {
    rm -f "${GROUP_BAK}" "${GROUP_NIS}"
    return
}

# input modified group
if [ $# -eq 0 ]
then
    HELP
    exit 1
fi
GROUP="${1}"
if [ ! -f "${GROUP}" ]
then
    HELP
    exit 1
fi

ldapsearch -Y EXTERNAL -H ldapi:// -LLL -b "ou=Group,${BASEDN}" cn=\* | awk -f "${AWKDIR}/quicksort.awk" -f "${AWKDIR}/ldap2group.awk" > "${GROUP_BAK}"
ldapstatus=${PIPESTATUS[0]}
if [ $ldapstatus -ne 0 ]
then
    exit 128
fi
maingroup="${LDIFDIR}/maingroup.${TIMESTAMP}"
if [ -f "${maingroup}" ]
then
    awk -f "${AWKDIR}/quicksort.awk" -f "${AWKDIR}/filter_group.awk" "${GROUP}" "${maingroup}" > "${GROUP_NIS}"
else
    awk -f "${AWKDIR}/quicksort.awk" -f "${AWKDIR}/filter_group.awk" "${GROUP}" > "${GROUP_NIS}"
fi
diff "${GROUP_BAK}" "${GROUP_NIS}" | awk -v "ldifdir=${LDIFDIR}" -v "TS=${TIMESTAMP}" -f "${AWKDIR}/group_diff2ldif.awk" "BASEDN=${BASEDN}" "SID=${sambaParam[sambaSID]}" "GID=${sambaParam[sambaNextGroupRid]}" "BASE=${sambaParam[sambaAlgorithmicRidBase]}"
remove_tmps
