/* ORIGINAL GTFS FEEDS */
/* Imported from consolidated MTA feeds upon GTFS update */

CREATE TABLE IF NOT EXISTS gtfs_feeds (
  feed_index SERIAL PRIMARY KEY,
  feed_start_date date not null,
  feed_end_date date not null,
  feed_download_date date not null,
  feed_url varchar(255)
);

CREATE TABLE IF NOT EXISTS gtfs_agency (
  feed_index integer not null,
  agency_id varchar(255) not null,
  agency_name varchar(255) not null,
  agency_url varchar(255) not null,
  agency_timezone varchar(255) not null,
  CONSTRAINT ga PRIMARY KEY (feed_index, agency_id)
);

CREATE TABLE IF NOT EXISTS gtfs_calendar (
  feed_index integer not null,
  service_id VARCHAR(27) NOT NULL, 
  monday integer NOT NULL, 
  tuesday integer NOT NULL, 
  wednesday integer NOT NULL, 
  thursday integer NOT NULL, 
  friday integer NOT NULL, 
  saturday integer NOT NULL, 
  sunday integer NOT NULL, 
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CONSTRAINT gc1 PRIMARY KEY (feed_index, service_id)
);

CREATE INDEX gc_start_date ON gtfs_calendar (start_date);
CREATE INDEX gc_end_date ON gtfs_calendar (end_date);

CREATE TABLE IF NOT EXISTS gtfs_calendar_dates (
  feed_index integer not null,
  service_id varchar(255) not null,
  date date not null,
  exception_type integer not null,
  CONSTRAINT gcd1 PRIMARY KEY(feed_index, service_id, date, exception_type),
  CONSTRAINT gcd2 UNIQUE(service_id, date, exception_type)
);

CREATE TABLE IF NOT EXISTS gtfs_routes (
  feed_index integer not null,
  route_id varchar(255) not null,
  agency_id varchar(255) not null,
  route_short_name varchar(255) not null,
  route_long_name varchar(255) not null,
  route_desc varchar(255) not null,
  route_type integer not null,
  route_url varchar(255) not null,
  route_color varchar(255) not null,
  route_text_color varchar(255) not null,
  CONSTRAINT gr PRIMARY KEY (feed_index, route_id)
);

CREATE TABLE IF NOT EXISTS gtfs_shapes (
  feed_index integer not null,
  shape_id varchar(255) not null,
  shape_pt_lat DECIMAL(8, 6) not null,
  shape_pt_lon DECIMAL(9, 6) not null,
  shape_pt_sequence int not null,
  CONSTRAINT gs PRIMARY KEY (feed_index, shape_id, shape_pt_sequence)
);

CREATE TABLE IF NOT EXISTS gtfs_stop_times (
  feed_index integer not null,
  trip_id varchar(255) not null,
  arrival_time time not null,
  departure_time time not null,
  stop_id varchar(255) not null,
  stop_sequence int not null,
  pickup_type integer not null,
  drop_off_type integer not null,
  CONSTRAINT gst PRIMARY KEY (feed_index, trip_id, stop_sequence)
);

CREATE TABLE IF NOT EXISTS gtfs_stops (
  feed_index integer not null,
  stop_id varchar(255) not null,
  stop_name varchar(255) not null,
  stop_desc varchar(255) not null,
  stop_lat DECIMAL(8, 6) not null,
  stop_lon DECIMAL(9, 6) not null,
  CONSTRAINT gs1 PRIMARY KEY (feed_index, stop_id)
);

CREATE TABLE IF NOT EXISTS gtfs_trips (
  feed_index integer not null,
  route_id varchar(255) not null,
  service_id varchar(255) not null,
  trip_id varchar(255) not null,
  trip_headsign varchar(255) not null,
  direction_id integer not null,
  shape_id varchar(255) not null,
  CONSTRAINT gt2 PRIMARY KEY (feed_index, trip_id),
  CONSTRAINT trip UNIQUE(trip_id)
);

