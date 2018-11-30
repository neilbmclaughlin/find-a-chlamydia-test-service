#!/bin/bash

# set -x

for lat_lon in "LS1 53.7974737203539 -1.55262247079646" "TS5 54.5504859692766 -1.25224782160555" "SE5 51.4737736224257 -0.0915219027459955"
# for i in "shi"
do
  echo ${lat_lon}
  size=20

  for i in "shi" "from16to24" "over24"
  do

    echo ${i}

    postcode=$(cut -f1 -d' ' <<< "${lat_lon}")
    lat=$(cut -f2 -d' ' <<< "${lat_lon}")
    lon=$(cut -f3 -d' ' <<< "${lat_lon}")

    sed_subs="s/_SIZE_/${size}/g;s/_LAT_/${lat}/g;s/_LON_/${lon}/g"
    as_query=$(sed "${sed_subs}" as-${i}-query.json)
    es_query=$(sed "${sed_subs}" es-${i}-query.json)
    curl -s -XPOST "https://nhsapidev.azure-api.net/service-search/search?api-version=1" -H "Content-Type: application/json" -H "subscription-key: ${API_SUB_KEY}" -d "${as_query}" | jq '.' > as-${i}-results.json
    curl -s  -XPOST https://es.staging.beta.nhschoices.net/sexual-health-services/_search -H 'Content-Type: application/json' -H 'cache-control: no-cache' -d "${es_query}" | jq '.' > es-${i}-results.json
    jq -C '.value[] | if .NACSCode then .NACSCode else .OrganisationID end' as-${i}-results.json | sort > as-${i}-id-sorted-list.json
    jq -C '.hits.hits[]._source | if .odsCode then .odsCode else .gsdId end' es-${i}-results.json | sort > es-${i}-id-sorted-list.json
    sdiff -l  as-${i}-id-sorted-list.json es-${i}-id-sorted-list.json | cat -n | grep -v -e '($'
    # diff -y --suppress-common-lines as-${i}-id-sorted-list.json es-${i}-id-sorted-list.json
  done
done
