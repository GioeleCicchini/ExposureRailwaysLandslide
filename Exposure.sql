create OR REPLACE function "__exposure"(id_point integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    point RECORD;
  BEGIN

    DROP TABLE IF EXISTS nearestzones;
    DROP TABLE IF EXISTS nearestisoipses;
    DROP TABLE IF EXISTS zonefragments;
    DROP TABLE IF EXISTS linearregression;
    DROP TABLE IF EXISTS hazardzones;
    DROP TABLE IF EXISTS landslide;


    CREATE TABLE points AS (SELECT * FROM railway_stations);

    FOR point IN SELECT * FROM points where gid=id_point LOOP
    PERFORM __nearestzonefinder(point.gid,700);
    PERFORM __nearestisoipsefinder(point.gid,750);
    PERFORM __zonefragmentsfinder();
    PERFORM __linearregressionfinder(point.gid,2);
    PERFORM __landslidefinder(point.gid,50);
    PERFORM __contributionoflandslide(point.gid,50);
    END LOOP;

	END;
$$;

