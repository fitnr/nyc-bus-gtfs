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

IMPORTFLAGS = FIELDS OPTIONALLY ENCLOSED BY '\"' \
	TERMINATED BY ',' \
	LINES TERMINATED BY '\n' \
	IGNORE 1 LINES

.PHONY: mysql mysql-% init

mysql: gtfs/$(GTFSVERSION)/calendar.txt $(addprefix mysql-,$(files))
	$(MYSQL) -e "INSERT gtfs_feeds SET feed_index = '$(GTFSVERSION)', \
	  feed_start_date = '$(shell csvcut -c start_date $< | csvstat --min | sed $(DATESED))', \
	  feed_end_date = '$(shell csvcut -c start_date $< | csvstat --max | sed $(DATESED))', \
	  feed_published_date = '$(shell echo $(GTFSVERSION) | sed $(DATESED))';"
	$(MYSQL) < import_gtfs.sql

$(addprefix mysql-,$(files)): mysql-%: $(foreach x,$(GTFSES),gtfs/$(GTFSVERSION)/$x/gtfs_%.txt)
	for file in $^; do \
	  $(MYSQL) --local-infile -e "LOAD DATA LOCAL INFILE '$$file' INTO TABLE gtfs_$(*F) \
	  $(IMPORTFLAGS) \
	  ($(COLUMNS_$(*F))) \
	  SET feed_index = '$(GTFSVERSION)'"; \
	done

.SECONDEXPANSION:

files_by_gtfs_prefix = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSVERSION)/$d/gtfs_$f.txt))
files_by_gtfs_pure = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSVERSION)/$d/$f.txt))

# Remove leading spaces (and we need to rename files, anyway)
$(files_by_gtfs_prefix): gtfs/$(GTFSVERSION)/%.txt: gtfs/$(GTFSVERSION)/$$(*D)/$$(subst gtfs_,,$$(*F)).txt
	sed 's/, \{1,\}/,/g' $< > $@

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
