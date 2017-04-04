shell = bash

include columns.ini

DATESED = 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/g'

BASE = http://web.mta.info/developers/data

TRANSITFEEDBASE = http://transitfeeds.com/p/mta

files = agency calendar calendar_dates routes shapes stop_times stops trips

GTFSDATE ?= $(shell date +"%Y%m%d")

ifdef TRANSITFEED

gtfses = bronx brooklyn manhattan queens staten_island

ifdef BUSCODATE
gtfses += busco
endif

else
gtfses = bronx brooklyn manhattan queens staten_island busco
endif

GTFSES = $(addprefix google_transit_,$(gtfses))

NYCTFILES = $(foreach x,bronx brooklyn manhattan queens staten_island,gtfs/$(GTFSDATE)/google_transit_$x.zip)

MYSQLFLAGS = -u $(USER) -p$(PASS)
DATABASE = nycbus
MYSQL = mysql $(DATABASE) $(MYSQLFLAGS)

convertdateformat = $(shell echo $(GTFSDATE) | sed $(DATESED))

IMPORTFLAGS = FIELDS OPTIONALLY ENCLOSED BY '\"' \
	TERMINATED BY ',' \
	LINES TERMINATED BY '\r\n' \
	IGNORE 1 LINES

.PHONY: gtfs mysql mysql-% init
.INTERMEDIATE: $(NYCTFILES)

mysql: $(addprefix mysql-,$(files))

$(addprefix mysql-,$(files)): mysql-%: $(foreach x,$(GTFSES),gtfs/$(GTFSDATE)/$x/gtfs_%.txt) | mysql-gtfs-feeds
	for file in $^; do \
	  $(MYSQL) --local-infile -e "LOAD DATA LOCAL INFILE '$$file' INTO TABLE gtfs_$(*F) \
	  $(IMPORTFLAGS) \
	  ($(COLUMNS_$(*F))) \
	  $(SET_$(*F))"; \
	done

mysql-gtfs-feeds: gtfs/$(GTFSDATE)/calendar.txt
	$(MYSQL) -e "INSERT gtfs_feeds SET \
	  feed_start_date = '$(shell csvstat -c start_date --min $< | sed $(DATESED))', \
	  feed_end_date = '$(shell csvstat -c end_date --max $< | sed $(DATESED))', \
	  feed_download_date = '$(convertdateformat)';"

gtfs/$(GTFSDATE)/calendar.txt: $(foreach d,$(GTFSES),gtfs/$(GTFSDATE)/$(d)/calendar.txt)
	csvstack $^ | csvcut -c start_date,end_date > $@

files_by_gtfs_prefix = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSDATE)/$d/gtfs_$f.txt))
files_by_gtfs_pure = $(foreach d,$(GTFSES),$(foreach f,$(files),gtfs/$(GTFSDATE)/$d/$f.txt))

gtfs: $(files_by_gtfs_pure)

.SECONDEXPANSION:

# Remove leading spaces (and we need to rename files, anyway)
$(files_by_gtfs_prefix): gtfs/$(GTFSDATE)/%.txt: gtfs/$(GTFSDATE)/$$(*D)/$$(subst gtfs_,,$$(*F)).txt
	sed 's/, \{1,\}/,/g' $< > $@

$(files_by_gtfs_pure): gtfs/$(GTFSDATE)/%.txt: gtfs/$(GTFSDATE)/$$(*D).zip | $$(@D)
	unzip -oqd $(@D) $< $(@F)
	@touch $@

ifdef TRANSITFEED

brooklyn = 80
bronx = 81
manhattan = 82
queens = 83
staten_island = 84

$(NYCTFILES): gtfs/$(GTFSDATE)/google_transit_%.zip: | gtfs/$(GTFSDATE)
	curl -L -o $@ $(TRANSITFEEDBASE)/$($*)/$(GTFSDATE)/download

gtfs/$(GTFSDATE)/google_transit_busco.zip: | gtfs/$(GTFSDATE)
	curl -L -o $@ $(TRANSITFEEDBASE)/85/$(BUSCODATE)/download

else

$(NYCTFILES): gtfs/$(GTFSDATE)/%.zip: | gtfs/$(GTFSDATE)
	curl $(BASE)/nyct/bus/$*.zip -o $@

gtfs/$(GTFSDATE)/google_transit_busco.zip: | gtfs/$(GTFSDATE)
	curl $(BASE)/busco/google_transit.zip -o $@

endif

gtfs/$(GTFSDATE) $(addprefix gtfs/$(GTFSDATE)/,$(GTFSES)):; mkdir -p $@

init: gtfs_schema.sql
	$(MYSQL) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE) DEFAULT CHARACTER SET = utf8;"
	$(MYSQL) < $<

clean: clean.sql; $(MYSQL) < $<

install:; pip install -r requirements.txt
