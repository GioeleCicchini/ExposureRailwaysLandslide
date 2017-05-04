CREATE OR REPLACE FUNCTION z_distancetolandslide (idstazione integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    particella_pericolosa RECORD;
    exposure FLOAT;
    station RECORD;
    avg_area FLOAT;
    impfact FLOAT;
    landslide GEOMETRY;


  BEGIN
    CREATE TABLE IF NOT EXISTS exposure_stations (
			gid INTEGER,
      name varchar,
			geom geometry,
			exposure FLOAT
		);

    exposure := 0;
    SELECT * INTO station FROM railway_stations WHERE gid = idstazione;
    SELECT avg(st_area(geom)) INTO avg_area FROM dataset;
    FOR particella_pericolosa IN (SELECT * FROM impact_voroni_on_station) LOOP

      IF (ST_Intersects(station.geom, particella_pericolosa.geom)) THEN
        exposure := exposure + (st_area(particella_pericolosa.geom) * particella_pericolosa.szk);
      ELSE

        SELECT geom INTO landslide FROM frane_su_stazione WHERE id_voronoi_polgyon = particella_pericolosa.id;
        impfact := (st_area(st_intersection(st_buffer(station.geom,100),landslide)))/(st_area(st_buffer(station.geom,100)));
        exposure := (exposure + (st_area(particella_pericolosa.geom) * particella_pericolosa.szk)/(st_distance(station.geom, st_centroid(particella_pericolosa.geom))))*impfact;
       -- exposure := (exposure + (st_area(particella_pericolosa.geom) * particella_pericolosa.szk))*impfact;


      END IF;
    END LOOP;
    INSERT INTO exposure_stations (gid, name, geom, exposure) VALUES (station.gid, station.name, station.geom, exposure/avg_area);

  END;
$$
