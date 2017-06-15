create or REPLACE function "__exposure"(id_point integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    point RECORD;
    exposure RECORD;
  BEGIN

    DROP TABLE IF EXISTS nearestzones;
    DROP TABLE IF EXISTS nearestisoipses;
    DROP TABLE IF EXISTS zonefragments;
    DROP TABLE IF EXISTS linearregression;
    DROP TABLE IF EXISTS hazardzones;
    DROP TABLE IF EXISTS landslide;
    DROP TABLE IF EXISTS exposure_stations;

        CREATE TABLE IF NOT EXISTS exposure_stations(
      id SERIAL PRIMARY KEY ,
			Building_gid INTEGER,
      name varchar,
			geom geometry,
			exposure FLOAT
		);

    DROP TABLE IF EXISTS points;
    CREATE TABLE points AS (SELECT * FROM railway_stations);


    FOR point IN SELECT * FROM points where gid=id_point LOOP
    PERFORM __nearestzonefinder(point.gid,800);
    PERFORM __nearestisoipsefinder(point.gid,850);
    PERFORM __zonefragmentsfinder();
    PERFORM __linearregressionfinder(point.gid,2.5);
    PERFORM __landslidefinder(point.gid,50);
    PERFORM __contributionoflandslide(point.gid,50);

    SELECT * FROM exposure LIMIT 1 INTO exposure;
    INSERT INTO exposure_stations (Building_gid, name, geom, exposure) VALUES (exposure.id, exposure.name, exposure.geom, exposure.exposure);
    END LOOP;

    PERFORM __cleartables();
	END;
$$;

SELECT __exposure(2);