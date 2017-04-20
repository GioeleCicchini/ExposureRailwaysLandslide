CREATE OR REPLACE FUNCTION z_exposure (idstazione integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    station RECORD;
  BEGIN

    DROP TABLE IF EXISTS nearstationpolygons;
    DROP TABLE IF EXISTS isoipsenearstation;
    DROP TABLE IF EXISTS ret;


    FOR station IN SELECT * FROM railway_stations where gid=idStazione LOOP
    PERFORM z_isoipsestationfinder(station.gid);
    PERFORM z_hotspotfinder(station.gid);
    PERFORM z_linemergeisoipse();

    PERFORM linearregression(station.gid);
    PERFORM z_franesustazione(station.gid);
    PERFORM z_distancetolandslide(station.gid);
    --DROP TABLE IF EXISTS nearstationpolygons;
    --DROP TABLE IF EXISTS isoipsenearstation;

    END LOOP;

	END;
$$
