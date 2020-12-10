#!/bin/bash

mkdir ./tmp

VERSION=`date -u "+%Y%m%d%H%M"`;
LAST_MODIFIED=`LC_ALL=en_GB.UTF-8 date -u "+%d %b %Y %H:%M %Z"`;

checksum_filter() {
  grep -v '! Checksum: ' $1 | grep -v '^$' > $1.chk
  CHKSUM=`cat $1.chk | openssl dgst -md5 -binary | openssl enc -base64 | cut -d "=" -f 1`
  rm -f ./$1.chk
  sed -i "/! Checksum: /c\! Checksum: $CHKSUM" $1
}

# Adblock Plus template
# https://adblockplus.org/en/filter-lists-requirements
TMP_ABP="./tmp/hufilter.txt"
cat "./dev/headers/adblock-plus.txt" >> "$TMP_ABP";
cat "./dev/ads.txt" >> "$TMP_ABP";
cat "./dev/other.txt" >> "$TMP_ABP";
echo "Adblock Plus list builded"

# uBlock template
TMP_UBLOCK="./tmp/hufilter-ublock.txt"
cat "./dev/headers/ublock.txt" >> "$TMP_UBLOCK";
cat "./dev/ads.txt" >> "$TMP_UBLOCK";
cat "./dev/annoyances.txt" >> "$TMP_UBLOCK";
cat "./dev/trackers.txt" >> "$TMP_UBLOCK";
cat "./dev/other.txt" >> "$TMP_UBLOCK";
cat "./dev/ublock-specific.txt" >> "$TMP_UBLOCK";
echo "uBlock list builded"

# Set version and last modified attribute in uBlock / ABP
sed -i $TMP_UBLOCK -e "s/#VERSION#/$VERSION/g; s/#LAST_MODIFIED#/$LAST_MODIFIED/g"
sed -i $TMP_ABP -e "s/#VERSION#/$VERSION/g; s/#LAST_MODIFIED#/$LAST_MODIFIED/g"

# Checksum uBlock / ABP filters
checksum_filter $TMP_ABP
checksum_filter $TMP_UBLOCK

# Generate AdGuard filter
TMP_ADGUARD="./tmp/hufilter-adguard.txt"
cat "./dev/headers/adguard.txt" >> "$TMP_ADGUARD";
#wget --output-document=./tmp/general_js_api.txt https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/general_js_api.txt
#cat "./tmp/general_js_api.txt" >> "$TMP_ADGUARD";
cat "./dev/ads.txt" >> "$TMP_ADGUARD";
cat "./dev/annoyances.txt" >> "$TMP_ADGUARD";
cat "./dev/trackers.txt" >> "$TMP_ADGUARD";
cat "./dev/other.txt" >> "$TMP_ADGUARD";
cat "./dev/adguard-specific.txt" >> "$TMP_ADGUARD";
echo "AdGuard list builded"

# Move out builded filters.
rm -f hufilter.txt
cp $TMP_ABP hufilter.txt
rm -f hufilter-abp.txt
cp $TMP_ABP hufilter-abp.txt
rm -f hufilter-ublock.txt
cp $TMP_UBLOCK hufilter-ublock.txt
rm -f hufilter-adguard.txt
cp $TMP_ADGUARD hufilter-adguard.txt

# Update DNS list (if it is necessary)
DNS_CURRENT=$(sort -u './hufilter-dns.txt' | grep -v '^!' | grep -v '^[[:space:]]*$')
DNS_NEW=$(sort -u './hufilter.txt' | grep ^\|\|.*\^$ | grep -v \/ | sed 's/^||//g; s/\^$//g')

if [ "$DNS_CURRENT" != "$DNS_NEW" ]; then
  # Generate DNS list for Pi-hole, AdGuard DNS, etc
  TMP_DNS='./hufilter-dns.tmp'
  cat './dev/headers/ublock.txt' > $TMP_DNS
  echo "$DNS_NEW" >> $TMP_DNS
  sed -i $TMP_DNS -e "s/#VERSION#/$VERSION/g; s/#LAST_MODIFIED#/$LAST_MODIFIED/g"
  checksum_filter $TMP_DNS
  mv $TMP_DNS hufilter-dns.txt
  echo "DNS list builded"
else
  echo "DNS list is up to date, no need to rebuild"
fi

# Remove tmp folder
rm -rf ./tmp
