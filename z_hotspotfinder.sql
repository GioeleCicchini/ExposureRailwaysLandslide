CREATE OR REPLACE FUNCTION z_hotspotfinder (stationid integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    station RECORD;
    particella RECORD;
    buffer geometry;

  BEGIN

    CREATE TEMP TABLE hotspottmp ( id serial PRIMARY KEY, id_station INTEGER, geom Geometry, szk FLOAT  ) ON COMMIT DROP;
    SELECT * INTO station FROM railway_stations where gid = stationid;

    buffer := (SELECT ST_Buffer(station.geom, 1000));

    FOR particella IN SELECT * FROM dataset LOOP
      IF ST_Intersects(buffer, particella.geom) THEN
        INSERT INTO hotspottmp (id_station, geom, szk) VALUES(station.gid, ST_Intersection(buffer, particella.geom), particella.szk );
      END IF;
    END LOOP;
    CREATE TABLE NearStationPolygons AS SELECT * FROM hotspottmp;
    DROP TABLE hotspottmp;



	END;
$$
