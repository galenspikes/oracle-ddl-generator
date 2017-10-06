#!/bin/bash

# Switches
for i in "$@"
do
case $i in
	--pwd=*) 
		SYSTEM_USER_PWD="${i#*=}" 
		shift;;
	--schema=*) 
		DB_SCHEMA="${i#*=}"	
		shift;;
	--owner=*) 
		DB_OWNER="${i#*=}" 
		shift;;
	--rt=*) # Database object types to return DDLs for (e.g. Table, View)
		REFTYPES+="${i#*=}"	
		shift;;
	--rn_excl=*) # Database objects to exclude
		REFNAMES+="${i#*=}"	
		shift;;
	--t=*) 
		TYPES+="${i#*=}" # (e.g. Package, Package Body)
		shift;;
	--host=*) # Name from tnsnames.ora
		DB_HOST="${i#*=}"	
		shift;;
	--port=*) 
		DB_PORT="${i#*=}"	
		shift;;
	--sid=*) 
		DB_SID="${i#*=}" 
		shift;;
	esac
done

IFS=',' read -r -a REFTYPES_ARR_TMP <<< "${REFTYPES}"
IFS=',' read -r -a TYPES_ARR_TMP <<< "${TYPES}"
REFTYPES_ARR="${REFTYPES_ARR_TMP[*]/ /_}"
TYPES_ARR="${TYPES_ARR_TMP[*]/ /_}"

SYSDATE=$(date +d%m%d%y-t%H%M%S)
GENERATOR_FILENAME='generate_'${DB_SCHEMA}'_ddl_scripts_'${SYSDATE}'.sql'
OUT_DIR=${DB_SCHEMA}'_'${SYSDATE}'_out'
GEN_DIR=${GENERATOR_FILENAME}

mkdir ${OUT_DIR}
mkdir ${GEN_DIR}

echo ${SYSTEM_USER_PWD}
echo ${DB_SCHEMA}
echo ${DB_OWNER}
echo ${REFTYPES_ARR[*]}
echo ${REFNAMES[*]}
echo ${TYPES_ARR[*]}
echo ${DB_HOST}

echo "Running: " sqlplus system/${SYSTEM_USER_PWD}@${DB_HOST} @master.sql ${DB_SCHEMA^^} ${DB_OWNER^^} ${GENERATOR_FILENAME} ${OUT_DIR} "${REFTYPES_ARR[*]^^}" "${REFNAMES[*]^^}" "${TYPES_ARR[*]^^}" ${GEN_DIR}

sqlplus system/${SYSTEM_USER_PWD}@${DB_HOST} @master.sql ${DB_SCHEMA^^} ${DB_OWNER^^} ${GENERATOR_FILENAME} ${OUT_DIR} "${REFTYPES_ARR[*]^^}" "${REFNAMES[*]^^}" "${TYPES_ARR[*]^^}" ${GEN_DIR}