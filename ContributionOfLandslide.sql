create or REPLACE function "__contributionoflandslide"(pointid integer, dr double precision) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    landslidezone RECORD;
    exposure FLOAT;
    CurrentPoint RECORD;
    avg_area FLOAT;
    impfact FLOAT;
    landslide GEOMETRY;
    distance FLOAT;

  BEGIN
    CREATE TABLE IF NOT EXISTS exposure (
      id SERIAL PRIMARY KEY,
			point_gid real,
			exposure FLOAT
		);

    exposure := 0;
    SELECT * INTO CurrentPoint FROM points WHERE gid = pointid;
    SELECT avg(st_area(geom)) INTO avg_area FROM zones;
    FOR landslidezone IN (SELECT * FROM landslidezones) LOOP

      IF (ST_Intersects(CurrentPoint.geom, landslidezone.geom)) THEN
        exposure := exposure + (st_area(landslidezone.geom) * landslidezone.szk);
      ELSE

        distance:=st_distance(CurrentPoint.geom, landslidezone.geom);
        SELECT geom INTO landslide FROM bufferedlinearregression WHERE bufferedlinearregression.id_zone = landslidezone.id;
        impfact := (st_area(st_intersection(st_buffer(CurrentPoint.geom,dr),landslide)))/(st_area(st_buffer(CurrentPoint.geom,dr)));
        exposure := (exposure + ((st_area(landslidezone.geom) * landslidezone.szk)*impfact));


      END IF;
    END LOOP;

    --INSERT INTO exposure (Building_gid, name, geom, exposure) VALUES (Building.gid, Building.name, Building.geom, exposure/avg_area);
    INSERT INTO exposure (point_gid, exposure) VALUES (CurrentPoint.gid, exposure/avg_area);
  END;
$$;
