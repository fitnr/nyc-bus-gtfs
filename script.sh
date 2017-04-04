#!/bin/bash

URL=$1
FILES="agency calendar calendar_dates routes shapes stop_times stops trips"

HASH=$(echo $URL | md5)

if [ ! -f "${HASH}.zip" ]; then
  echo curl -o "${HASH}.zip" "${URL}"
  curl -L -o "${HASH}.zip" "${URL}"
fi

mkdir -p $HASH

for file in ${FILES}
do
  if [ ! -f "${HASH}/${file}.txt" ]; then
    unzip -p "${HASH}.zip" "${file}.txt" |
    sed 's/, \{1,\}/,/g' > "${HASH}/${file}.txt"
  fi
done

IMPORTFLAGS="FIELDS OPTIONALLY ENCLOSED BY '\"' TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES"

mysql nycbus -e "INSERT gtfs_feeds SET feed_url = '${URL}'"
FEED_INDEX=$(mysql nycbus --skip-column-names -e "SELECT feed_index FROM gtfs_feeds WHERE feed_url='${URL}' LIMIT 1")

echo FEED_INDEX="$FEED_INDEX"

mysql nycbus --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/stops.txt' IGNORE INTO TABLE gtfs_stops ${IMPORTFLAGS} (stop_id,stop_name,stop_desc,stop_lat,stop_lon) SET feed_index = $FEED_INDEX"

echo "importing agency.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/agency.txt' IGNORE INTO TABLE gtfs_agency \
  ${IMPORTFLAGS} (agency_id,agency_name,agency_url,agency_timezone) SET feed_index = $FEED_INDEX"

echo "importing calendar.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/calendar.txt' IGNORE INTO TABLE gtfs_calendar \
  ${IMPORTFLAGS} (service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday, @start_date, @end_date) \
  SET start_date = STR_TO_DATE(@start_date, '%Y%c%d'), end_date = STR_TO_DATE(@end_date, '%Y%c%d'), \
  feed_index = $FEED_INDEX"

echo "importing calendar_dates.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/calendar_dates.txt' IGNORE INTO TABLE gtfs_calendar_dates \
  ${IMPORTFLAGS} (service_id, @date, exception_type) \
  SET date = STR_TO_DATE(@date, '%Y%c%d'), feed_index = $FEED_INDEX"

echo "importing routes.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/routes.txt' IGNORE INTO TABLE gtfs_routes \
  ${IMPORTFLAGS} \
  (route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color) \
  SET feed_index = $FEED_INDEX"

echo "importing shapes.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/shapes.txt' IGNORE INTO TABLE gtfs_shapes \
  ${IMPORTFLAGS} (shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence) \
  SET feed_index = $FEED_INDEX"

echo "importing stop_times.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/stop_times.txt' IGNORE INTO TABLE gtfs_stop_times \
  ${IMPORTFLAGS} (trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) \
  SET feed_index = $FEED_INDEX"

echo "importing stops.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/stops.txt' IGNORE INTO TABLE gtfs_stops \
  ${IMPORTFLAGS} (stop_id,stop_name,stop_desc,stop_lat,stop_lon) SET feed_index = $FEED_INDEX"

echo "importing trips.txt"
mysql nycbus  --local-infile -e "LOAD DATA LOCAL INFILE '${HASH}/trips.txt' IGNORE INTO TABLE gtfs_trips \
  ${IMPORTFLAGS} (route_id,service_id,trip_id,trip_headsign,direction_id,shape_id) \
  SET feed_index = $FEED_INDEX"

for file in ${FILES}; do
  rm "${file}.txt"
done

mysql nycbus -e "UPDATE gtfs_feeds SET \
  feed_start_date = (SELECT MIN(start_date) FROM gtfs_calendar WHERE feed_index=${FEED_INDEX}), \
  feed_end_date = (SELECT MAX(end_date) FROM gtfs_calendar WHERE feed_index=${FEED_INDEX})"
