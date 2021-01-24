#!/bin/bash

set -e
delete=

# create links
create_links() {
    urls="$1" project="$2"
for index in ${!urls[@]}; do
  if [ $((index % 2)) == 0 ]; then
    echo "${urls[index+1]}:${urls[index]}"
cat <<EOF | oc apply -f -
apiVersion: console.openshift.io/v1
kind: ConsoleLink
metadata:
  name: "${urls[index+1]}"
spec:
  applicationMenu:
    imageURL: >-
      {{ .image_url }}
    section: "$project"
  href: "https://${urls[index]}"
  location: ApplicationMenu
  text: "${urls[index+1]}"
EOF
  fi
done
}

# delete links
delete_links() {
    urls="$1" project="$2"
for index in ${!urls[@]}; do
  if [ $((index % 2)) == 0 ]; then
    echo "${urls[index+1]}:${urls[index]}"
    oc delete consolelink "${urls[index+1]}"
  fi
done
}

usage() {
  cat <<EOF 2>&1
usage: $0 [ -d ] 

create or delete ocp console links from current project
    -d      delete consolelinks
    -h      help
EOF
  exit 1
}

while getopts duh c;
do
  case $c in    
      d)
          delete=1
          ;;
      *)
          usage
          ;;
  esac
done

shift `expr $OPTIND - 1`

rc=0
oc whoami 1,2>/dev/null || rc=$?
if [ "${rc}" -ne 0 ]; then
    echo "try oc login first?"
    exit 1;
fi    

read -r -a urls <<< $(echo -n $(oc get route --no-headers -o custom-columns=ROUTE:.spec.host,NAME:.metadata.name))

project=$(oc project -q)

if [ -z "$urls" ] || [ -z "$project" ]; then
    echo "could not find any urls or project, try switching project?"
    exit 1;
fi

if [ -n "$delete" ]; then
    delete_links "$urls" "$project"
else
    create_links "$urls" "$project"
fi
