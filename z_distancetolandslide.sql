CREATE OR REPLACE FUNCTION z_distancetolandslide (idstazione integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    particella_pericolosa RECORD;
    exposure FLOAT;
    station RECORD;
    avg_area FLOAT;

  BEGIN
    exposure := 0;
    SELECT * INTO station FROM railway_stations WHERE gid = idstazione;
    SELECT avg(st_area(geom)) INTO avg_area FROM dataset;
    FOR particella_pericolosa IN (SELECT * FROM impact_voroni_on_station) LOOP
        exposure := exposure + (st_area(particella_pericolosa.geom) * particella_pericolosa.szk);
    END LOOP;
    INSERT INTO exposure_stations (gid, name, geom, exposure) VALUES (station.gid, station.name, station.geom, exposure/avg_area);
	END;
$$
