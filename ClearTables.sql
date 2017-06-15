create or REPLACE function "__cleartables"() returns void
LANGUAGE plpgsql
AS $$
DECLARE

  BEGIN

    DROP TABLE IF EXISTS nearestzones;
    DROP TABLE IF EXISTS nearestisoipses;
    DROP TABLE IF EXISTS zonefragments;
    DROP TABLE IF EXISTS linearregression;
    DROP TABLE IF EXISTS hazardzones;
    DROP TABLE IF EXISTS landslide;
    DROP TABLE IF EXISTS exposure;
    DROP TABLE IF EXISTS points;
    DROP TABLE IF EXISTS slope_table;
    DROP TABLE IF EXISTS sotto_tratte_temp;

	END;
$$;
