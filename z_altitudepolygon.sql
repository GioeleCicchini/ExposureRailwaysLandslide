CREATE FUNCTION z_altitudepolygon () RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    cursore RECORD;
    poligono RECORD;
  BEGIN
   DROP TABLE IF EXISTS finale;

      CREATE TABLE finale(
        id SERIAL,
        geom GEOMETRY,
        elevation INTEGER
      );

      FOR poligono IN SELECT * FROM poligonistazione LOOP

         CREATE TABLE poligono3d(
        geom geometry,
        elevation INTEGER
        );

        INSERT INTO poligono3d (SELECT (ST_DumpPoints(poligonistazione.geom)).geom FROM poligonistazione WHERE id= poligono.id);
      FOR cursore IN SELECT * FROM poligono3d LOOP
      UPDATE poligono3d SET elevation =
       (SELECT isoipsenearstation.elevation FROM isoipsenearstation WHERE st_intersects(isoipsenearstation.geom,poligono3d.geom) LIMIT 1);
      END LOOP;


    INSERT INTO finale(geom,elevation) SELECT poligonistazione.geom,(SELECT avg(elevation) FROM poligono3d) FROM poligonistazione WHERE id=poligono.id;

      DROP TABLE poligono3d;

      END LOOP;





	END;
$$
