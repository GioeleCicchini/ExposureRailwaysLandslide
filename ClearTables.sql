create or REPLACE function "__cleartables"() returns void
LANGUAGE plpgsql
AS $$
DECLARE

  BEGIN

    DROP TABLE IF EXISTS nearestzones;
    DROP TABLE IF EXISTS nearestisoipses;
    DROP TABLE IF EXISTS zonefragments;
    DROP TABLE IF EXISTS bufferedlinearregression;
    DROP TABLE IF EXISTS landslidezones;
    DROP TABLE IF EXISTS landslide;
    DROP TABLE IF EXISTS exposure;
    DROP TABLE IF EXISTS points;
    DROP TABLE IF EXISTS slope_table;
    DROP TABLE IF EXISTS current_route_segments;

	END;
$$;
