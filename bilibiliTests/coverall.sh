#!/bin/bash

trim()
{
    trimmed=$1
    trimmed=${trimmed%% }
    trimmed=${trimmed## }

    echo $trimmed
}

# declare BUILT_PRODUCTS_DIR CURRENT_ARCH OBJECT_FILE_DIR_normal SRCROOT OBJROOT 
declare -r xctoolVars=$(xctool -showBuildSettings | egrep '(BUILT_PRODUCTS_DIR)|(CURRENT_ARCH)|(OBJECT_FILE_DIR_normal)|(SRCROOT)|(OBJROOT)' |  egrep -v 'Pods')
while read line; do
	declare key=$(echo "${line}" | cut -d "=" -f1)
	declare value=$(echo "${line}" | cut -d "=" -f2)
	printf -v "`trim ${key}`" "`trim ${value}`" # https://sites.google.com/a/tatsuo.jp/programming/Home/bash/hentai-bunpou-saisoku-masuta
done < <( echo "${xctoolVars}" )

declare -r gcov_dir="${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}/"

## ======

generateGcov()
{
	#  doesn't set output dir to gcov...
	cd "${gcov_dir}"
	for file in ${gcov_dir}/*.gcda
	do
		gcov-4.2 "${file}" -o "${gcov_dir}"
	done
	cd -
}

copyGcovToProjectDir()
{
	cp -r "${gcov_dir}" gcov
}

removeGcov(){
	rm -r gcov
}

main()
{

# generate + copy
 	generateGcov
	copyGcovToProjectDir
# post
	coveralls ${@+"$@"}
# clean up
	removeGcov	
}

main ${@+"$@"}
