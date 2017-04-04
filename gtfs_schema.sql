/* ORIGINAL GTFS FEEDS */
/* Imported from consolidated MTA feeds upon GTFS update */

DROP TABLE IF EXISTS gtfs_feeds;
CREATE TABLE gtfs_feeds (
  feed_index INTEGER(4) not null AUTO_INCREMENT PRIMARY KEY,
  feed_start_date date not null,
  feed_end_date date not null,
  feed_download_date date not null,
  feed_url varchar(255) not null
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_agency;
CREATE TABLE gtfs_agency (
  feed_index INTEGER(4) not null,
  agency_id varchar(255) not null,
  agency_name varchar(255) not null,
  agency_url varchar(255) not null,
  agency_timezone varchar(255) not null,
  PRIMARY KEY (feed_index, agency_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_calendar;
CREATE TABLE gtfs_calendar (
  feed_index INTEGER(4) not null,
  service_id VARCHAR(27) NOT NULL, 
  monday TINYINT(1) NOT NULL, 
  tuesday TINYINT(1) NOT NULL, 
  wednesday TINYINT(1) NOT NULL, 
  thursday TINYINT(1) NOT NULL, 
  friday TINYINT(1) NOT NULL, 
  saturday TINYINT(1) NOT NULL, 
  sunday TINYINT(1) NOT NULL, 
  start_date DATE NOT NULL, 
  end_date DATE NOT NULL,
  PRIMARY KEY (feed_index, service_id),
  KEY start_date (start_date),
  KEY end_date (end_date)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_calendar_dates;
CREATE TABLE gtfs_calendar_dates (
  feed_index INTEGER(4) not null,
  service_id varchar(255) not null,
  date date not null,
  exception_type tinyint not null,
  PRIMARY KEY (feed_index,service_id, date, exception_type),
  UNIQUE KEY service_id (service_id, date, exception_type)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_routes;
CREATE TABLE gtfs_routes (
  feed_index INTEGER(4) not null,
  route_id varchar(255) not null,
  agency_id varchar(255) not null,
  route_short_name varchar(255) not null,
  route_long_name varchar(255) not null,
  route_desc varchar(255) not null,
  route_type tinyint not null,
  route_url varchar(255) not null,
  route_color varchar(255) not null,
  route_text_color varchar(255) not null,
  PRIMARY KEY (feed_index,route_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_shapes;
CREATE TABLE gtfs_shapes (
  feed_index INTEGER(4) not null,
  shape_id varchar(255) not null,
  shape_pt_lat DECIMAL(8, 6) not null,
  shape_pt_lon DECIMAL(9, 6) not null,
  shape_pt_sequence int not null,
  PRIMARY KEY (feed_index, shape_id, shape_pt_sequence)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_stop_times;
CREATE TABLE gtfs_stop_times (
  feed_index INTEGER(4) not null,
  trip_id varchar(255) not null,
  arrival_time time not null,
  departure_time time not null,
  stop_id varchar(255) not null,
  stop_sequence int not null,
  pickup_type tinyint not null,
  drop_off_type tinyint not null,
  PRIMARY KEY (feed_index, trip_id, stop_sequence)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_stops;
CREATE TABLE gtfs_stops (
  feed_index INTEGER(4) not null,
  stop_id varchar(255) not null,
  stop_name varchar(255) not null,
  stop_desc varchar(255) not null,
  stop_lat DECIMAL(8, 6) not null,
  stop_lon DECIMAL(9, 6) not null,
  PRIMARY KEY (feed_index, stop_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS gtfs_trips;
CREATE TABLE gtfs_trips (
  feed_index INTEGER(4) not null,
  route_id varchar(255) not null,
  service_id varchar(255) not null,
  trip_id varchar(255) not null,
  trip_headsign varchar(255) not null,
  direction_id tinyint not null,
  shape_id varchar(255) not null,
  PRIMARY KEY (feed_index, trip_id),
  UNIQUE KEY trip_id (trip_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
