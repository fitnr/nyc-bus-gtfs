shell = bash

include columns.ini

DATESED = 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/g'

BASE = http://web.mta.info/developers/data

TRANSITFEED = http://transitfeeds.com/p/mta

files = agency calendar calendar_dates routes shapes stop_times stops trips

GTFSVERSION ?= $(shell date +"%Y%m%d")

ifdef USE_TRANSITFEED

gtfses = bronx brooklyn manhattan queens staten_island

ifdef BUSCOVERSION
gtfses += busco
endif

else
gtfses = bronx brooklyn manhattan queens staten_island busco
endif

GTFSES = $(addprefix google_transit_,$(gtfses))

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

mysql-gtfs-feeds: gtfs/$(GTFSVERSION)/calendar.txt
	$(MYSQL) -e "INSERT gtfs_feeds SET \
	  feed_start_date = '$(shell csvstat -c start_date --min $< | sed $(DATESED))', \
	  feed_end_date = '$(shell csvstat -c end_date --max $< | sed $(DATESED))', \
	  feed_download_date = '$(convertdateformat)';"

gtfs/$(GTFSVERSION)/calendar.txt: $(foreach d,$(GTFSES),gtfs/$(GTFSVERSION)/$(d)/calendar.txt)
	csvstack $^ | csvcut -c start_date,end_date > $@

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

ifdef USE_TRANSITFEED

brooklyn = 80
bronx = 81
manhattan = 82
queens = 83
staten_island = 84

$(NYCTFILES): gtfs/$(GTFSVERSION)/google_transit_%.zip: | gtfs/$(GTFSVERSION)
	curl -L -o $@ $(TRANSITFEED)/$($*)/$(GTFSVERSION)/download

gtfs/$(GTFSVERSION)/google_transit_busco.zip: | gtfs/$(GTFSVERSION)
	curl -L -o $@ $(TRANSITFEED)/85/$(BUSCOVERSION)/download

else

$(NYCTFILES): gtfs/$(GTFSVERSION)/%.zip: | gtfs/$(GTFSVERSION)
	curl $(BASE)/nyct/bus/$*.zip -o $@

gtfs/$(GTFSVERSION)/google_transit_busco.zip: | gtfs/$(GTFSVERSION)
	curl $(BASE)/busco/google_transit.zip -o $@

endif

gtfs/$(GTFSVERSION) $(addprefix gtfs/$(GTFSVERSION)/,$(GTFSES)):; mkdir -p $@

init: gtfs_schema.sql
	$(MYSQL) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE) DEFAULT CHARACTER SET = utf8;"
	$(MYSQL) < $<

clean: clean.sql; $(MYSQL) < $<
