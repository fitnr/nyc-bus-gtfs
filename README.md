# NYC Bus GTFS downloader

This repo downloads NYC bus GTFS data and loads it into a MySQL database, tracking different versions of the data.

## Requirements
* MySQL
* bash command line environment
* csvkit

## Install

`sudo make install`

## Usage

(If using a `~/.my.cnf` file, append `MYSQLFLAGS=` to all commands.)

```
make init DATABASE=name_of_your_database
```

The `name_of_your_database` defaults to `nycbus`.

Download the current GTFS dataset. This places the files in a folder named `gtfs/YYYYMMDD`. The assumption is that you may, in the future, download a newer version of the GTFS.
```
make gtfs
```

Load the downloaded GTFS into the MySQL database
```
make mysql DATABASE=name_of_your_database
```

If a day goes by, or you have older GTFS data to load, use the GTFSDATE variable:
```
make mysql GTFSDATE=20170319
```

## Download from transitfeed

````
# download NYCT data and Bus Company data, which often have a different date
make TRANSITFEED=YES GTFSDATE=20151223 BUSCODATE=20151227 gtfs
````

The data will be put in the 

## Schema

The database will contain tables for each entry file in the GTFS schema. One additional column appears on each, `feed_index`, which is an integer keyed to the `gtfs_feeds` table. The `gtfs_feeds` contains a record of the `feed_start_date`, `feed_end_date` and `feed_download_date`.
