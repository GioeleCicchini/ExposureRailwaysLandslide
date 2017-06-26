create or REPLACE function "__nearestzonefinder"(id_point integer, r integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    station RECORD;
    particella RECORD;
    hazardArea geometry;

  BEGIN

    CREATE TEMP TABLE hotspottmp ( id serial PRIMARY KEY, id_station INTEGER, geom Geometry, szk FLOAT  ) ON COMMIT DROP;
    SELECT * INTO station FROM points where gid = id_point;

    hazardArea := (SELECT ST_Buffer(station.geom, r));

    FOR particella IN SELECT * FROM zones LOOP
      IF ST_Intersects(hazardArea, particella.geom) THEN
        INSERT INTO hotspottmp (id_station, geom, szk) VALUES(station.gid, ST_Intersection(hazardArea, particella.geom), particella.szk );
      END IF;
    END LOOP;
    CREATE TABLE NearestZones AS SELECT * FROM hotspottmp;
    DROP TABLE hotspottmp;



	END;
$$;
