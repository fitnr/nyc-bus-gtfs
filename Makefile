shell = bash

include columns.ini

DATESED = 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/g'

BASE = http://web.mta.info/developers/data

files = agency calendar calendar_dates routes shapes stop_times stops trips

GTFSVERSION ?= $(shell date +"%Y%m%d")

GTFSES = $(addprefix google_transit_,bronx brooklyn manhattan queens staten_island busco)

NYCTFILES = $(foreach x,bronx brooklyn manhattan queens staten_island,gtfs/$(GTFSVERSION)/google_transit_$x.zip)

MYSQLFLAGS = -u $(USER) -p$(PASS)
DATABASE = nycbus
MYSQL = mysql $(DATABASE) $(MYSQLFLAGS)

convertdateformat = $(shell echo $(GTFSVERSION) | sed $(DATESED))

IMPORTFLAGS = FIELDS OPTIONALLY ENCLOSED BY '\"' \
	TERMINATED BY ',' \
	LINES TERMINATED BY '\n' \
	IGNORE 1 LINES

.PHONY: gtfs mysql mysql-% init
.INTERMEDIATE: $(NYCTFILES)

mysql: $(addprefix mysql-,$(files))

$(addprefix mysql-,$(files)): mysql-%: $(foreach x,$(GTFSES),gtfs/$(GTFSVERSION)/$x/gtfs_%.txt) | mysql-gtfs-feeds
	for file in $^; do \
	  $(MYSQL) --local-infile -e "LOAD DATA LOCAL INFILE '$$file' INTO TABLE gtfs_$(*F) \
	  $(IMPORTFLAGS) \
	  ($(COLUMNS_$(*F))) \
	  SET $(SET_$(*F)) \
	    feed_index = (SELECT feed_index from gtfs_feeds WHERE feed_download_date = '$(convertdateformat)')"; \
	done

mysql-gtfs-feeds: gtfs/$(GTFSVERSION)/google_transit_manhattan/calendar.txt
	$(MYSQL) -e "INSERT gtfs_feeds SET \
	  feed_start_date = '$(shell csvcut -c start_date $< | csvstat --min | sed $(DATESED))', \
	  feed_end_date = '$(shell csvcut -c start_date $< | csvstat --max | sed $(DATESED))', \
	  feed_download_date = '$(convertdateformat)';"

files_by_gtfs_prefix = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSVERSION)/$d/gtfs_$f.txt))
files_by_gtfs_pure = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSVERSION)/$d/$f.txt))

gtfs: $(files_by_gtfs_pure)

.SECONDEXPANSION:

# Remove leading spaces (and we need to rename files, anyway)
$(files_by_gtfs_prefix): gtfs/$(GTFSVERSION)/%.txt: gtfs/$(GTFSVERSION)/$$(*D)/$$(subst gtfs_,,$$(*F)).txt
	sed 's/, \{1,\}/,/g' $< | \
	tr -d '\r' > $@

$(files_by_gtfs_pure): gtfs/$(GTFSVERSION)/%.txt: gtfs/$(GTFSVERSION)/$$(*D).zip | $$(@D)
	unzip -oqd $(@D) $< $(@F)
	@touch $@

$(NYCTFILES): gtfs/$(GTFSVERSION)/%.zip: | gtfs/$(GTFSVERSION)
	curl $(BASE)/nyct/bus/$*.zip -o $@

gtfs/$(GTFSVERSION)/google_transit_busco.zip: | gtfs/$(GTFSVERSION)
	curl $(BASE)/busco/google_transit.zip -o $@

gtfs/$(GTFSVERSION) $(addprefix gtfs/$(GTFSVERSION)/,$(GTFSES)):; mkdir -p $@

init: gtfs_schema.sql
	$(MYSQL) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE) DEFAULT CHARACTER SET = utf8;"
	$(MYSQL) < $<

clean: clean.sql; $(MYSQL) < $<
