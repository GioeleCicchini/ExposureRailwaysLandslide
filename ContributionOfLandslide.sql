create function "__contributionoflandslide"(idstazione integer, dr double precision) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    hazard_zone RECORD;
    exposure FLOAT;
    Building RECORD;
    avg_area FLOAT;
    impfact FLOAT;
    landslide GEOMETRY;
    distance FLOAT;


  BEGIN
    CREATE TABLE IF NOT EXISTS exposure (
      id SERIAL PRIMARY KEY ,
			Building_gid INTEGER,
      name varchar,
			geom geometry,
			exposure FLOAT
		);

    exposure := 0;
    SELECT * INTO Building FROM points WHERE gid = idstazione;
    SELECT avg(st_area(geom)) INTO avg_area FROM dataset;
    FOR hazard_zone IN (SELECT * FROM hazardzones) LOOP

      IF (ST_Intersects(Building.geom, hazard_zone.geom)) THEN
        exposure := exposure + (st_area(hazard_zone.geom) * hazard_zone.szk);
      ELSE

        distance:=st_distance(Building.geom, hazard_zone.geom);
        SELECT geom INTO landslide FROM linearregression WHERE linearregression.id_zone = hazard_zone.id;
        impfact := (st_area(st_intersection(st_buffer(Building.geom,dr),landslide)))/(st_area(st_buffer(Building.geom,dr)));
        exposure := (exposure + ((st_area(hazard_zone.geom) * hazard_zone.szk)*impfact));


      END IF;
    END LOOP;
    INSERT INTO exposure (Building_gid, name, geom, exposure) VALUES (Building.gid, Building.name, Building.geom, exposure/avg_area);

  END;
$$;
