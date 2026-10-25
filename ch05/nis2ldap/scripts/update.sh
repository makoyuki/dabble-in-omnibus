#!/bin/bash
# This program depends on "ypcat passwd" and "ypcat group"
# 

function HELP(){
    printf "update.sh\n"
}

SCRIPTSDIR=/usr/local/etc/openldap/scripts
PARAM="${SCRIPTSDIR}/ldap_params.sh"
MASTER2LDIF="${SCRIPTSDIR}/master2ldif.sh"
GROUP2LDIF="${SCRIPTSDIR}/group2ldif.sh"
if [ ! -f "${PARAM}" ]
then
    echo "Fatal Error!" >&2
    exit 1
fi
if [ ! -f "${MASTER2LDIF}" ]
then
    echo "Fatal Error!" >&2
    exit 1
fi
if [ ! -f "${GROUP2LDIF}" ]
then
    echo "Fatal Error!" >&2
    exit 1
fi
. "${PARAM}"
echo TIMESTAMP=${TIMESTAMP}

# OPT="-v -n"
OPT="-v"

NISPASSWD="${TMPDIR}/nis.passwd"
NISGROUP="${TMPDIR}/nis.group"

ypcat master.passwd > "${NISPASSWD}"
if [ $? -ne 0 ]
then
    echo "Error: ypcat master.passwd" >&2
    exit 1
fi

ypcat group > "${NISGROUP}"
if [ $? -ne 0 ]
then
    echo "Error: ypcat group" >&2
    exit 1
fi

# ---
# update: ou=People,dc=example,dc=jp
# ---
TARGET=users
MKLDIF="${MASTER2LDIF}"

ADD_LDIF="${LDIFDIR}/add_${TARGET}.${TIMESTAMP}.ldif"
MOD_LDIF="${LDIFDIR}/mod_${TARGET}.${TIMESTAMP}.ldif"
DELETE="${LDIFDIR}/del_${TARGET}.${TIMESTAMP}"

ORGIFS="${IFS}"
echo "${MKLDIF}" "${NISPASSWD}"
"${MKLDIF}" "${NISPASSWD}"
echo $? $ADD_LDIF $MOD_LDIF $DELETE
if [ -f "${ADD_LDIF}" ]
then
    echo ldapadd ${OPT} -Y EXTERNAL -H ldapi:// -f "${ADD_LDIF}"
    ldapadd ${OPT} -Y EXTERNAL -H ldapi:// -f "${ADD_LDIF}"
fi
if [ -f "${MOD_LDIF}" ]
then
    echo ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// -f "${MOD_LDIF}"
    ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// -f "${MOD_LDIF}"
fi
if [ -f "${DELETE}" ]
then
    #export IFS=$'\n'
    for name in $( cat "${DELETE}" )
    do
	#export IFS="${ORGIFS}"
	echo ldapdelete ${OPT} -Y EXTERNAL -H ldapi:// "${name}"
	ldapdelete ${OPT} -Y EXTERNAL -H ldapi:// "${name}"
	#export IFS=$'\n'
    done
    #export IFS="${ORGIFS}"
fi

# ---
# update: ou=Group,dc=example,dc=jp
# ---
TARGET=group
MKLDIF="${GROUP2LDIF}"

ADD_LDIF="${LDIFDIR}/add_${TARGET}.${TIMESTAMP}.ldif"
MOD_LDIF="${LDIFDIR}/mod_${TARGET}.${TIMESTAMP}.ldif"
DELETE="${LDIFDIR}/del_${TARGET}.${TIMESTAMP}"

echo "${MKLDIF}" "${NISGROUP}"
"${MKLDIF}" "${NISGROUP}"
echo $? $ADD_LDIF $MOD_LDIF $DELETE
if [ -f "${ADD_LDIF}" ]
then
    echo ldapadd ${OPT} -Y EXTERNAL -H ldapi:// -f "${ADD_LDIF}"
    ldapadd ${OPT} -Y EXTERNAL -H ldapi:// -f "${ADD_LDIF}"
fi
if [ -f "${MOD_LDIF}" ]
then
    echo ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// -f "${MOD_LDIF}"
    ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// -f "${MOD_LDIF}"
fi
if [ -f "${DELETE}" ]
then
    #export IFS="\n"
    for name in $( cat "${DELETE}" )
    do
	#export IFS="${ORGIFS}"
	echo ldapdelete ${OPT} -Y EXTERNAL -H ldapi:// "${name}"
	ldapdelete ${OPT} -Y EXTERNAL -H ldapi:// "${name}"
	#export IFS="\n"
    done
    #export IFS="${ORGIFS}"
fi

nextUserRidTxt="${LDIFDIR}/sambaNextUserRid.${TIMESTAMP}.txt"
nextGroupRidTxt="${LDIFDIR}/sambaNextGroupRid.${TIMESTAMP}.txt"
prev_userRidNumber="${sambaParam[sambaNextUserRid]}"
prev_groupRidNumber="${sambaParam[sambaNextGroupRid]}"

if [ -f "${nextUserRidTxt}" ]
then
    next_userRidNumber=$( cat "${nextUserRidTxt}" )
    if [ $prev_userRidNumber -ne $next_userRidNumber ]
    then
	ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// <<EOF
dn: sambaDomainName=${sambaDomain},${BASEDN}
changetype: modify
replace: sambaNextUserRid
sambaNextUserRid: ${next_userRidNumber}
EOF
    fi
fi
if [ -f "${nextGroupRidTxt}" ]
then
    next_groupRidNumber=$( cat "${nextGroupRidTxt}" )
    if [ $prev_groupRidNumber -ne $next_groupRidNumber ]
    then
	ldapmodify ${OPT} -Y EXTERNAL -H ldapi:// <<EOF
dn: sambaDomainName=${sambaDomain},${BASEDN}
changetype: modify
replace: sambaNextGroupRid
sambaNextGroupRid: ${next_groupRidNumber}
EOF
    fi
fi
