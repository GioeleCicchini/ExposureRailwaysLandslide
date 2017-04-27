CREATE OR REPLACE FUNCTION z_franesustazione (stationid integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
		frana RECORD;
		stationBuffer geometry;
  BEGIN

		 CREATE TABLE frane_su_stazione (
      id SERIAL,
      geom geometry,
      id_voronoi_polgyon INTEGER
    );

		CREATE TABLE impact_voroni_on_station (
			id INTEGER,
			geom geometry,
			szk FLOAT
		);

		SELECT st_buffer(geom, 100) INTO stationBuffer FROM railway_stations WHERE gid = stationid;

		FOR frana IN (SELECT * FROM ret) LOOP
			IF st_intersects(stationBuffer, frana.geom) THEN
				INSERT INTO frane_su_stazione (geom, id_voronoi_polgyon) VALUES (frana.geom, frana.id_voronoi_polgyon);
				INSERT INTO impact_voroni_on_station (SELECT id, geom, szk FROM nearstationpolygons WHERE id = frana.id_voronoi_polgyon);
			END IF;
		END LOOP;
	END;
$$
