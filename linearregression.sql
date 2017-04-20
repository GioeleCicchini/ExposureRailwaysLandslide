CREATE FUNCTION linearregression (stationid integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    x DOUBLE PRECISION;
    y DOUBLE PRECISION;
    xp DOUBLE PRECISION;
    yp DOUBLE PRECISION;
    slope DOUBLE PRECISION;
    current_id_voronoi_polygon INTEGER;
    line_buffer FLOAT;
  BEGIN

    CREATE TABLE ret (
      id SERIAL,
      geom geometry(Polygon),
      id_voronoi_polgyon INTEGER
    );

    DELETE FROM poligonistazione WHERE ST_Area(geom) < 0.01;

    FOR current_id_voronoi_polygon IN SELECT id FROM nearstationpolygons LOOP
      DROP TABLE IF EXISTS punti;
      DROP TABLE IF EXISTS centroidihotspot;
      DROP TABLE IF EXISTS slope_table;
      DROP TABLE IF EXISTS centroid_polygon;

      CREATE TEMP TABLE punti(
        geom GEOMETRY
      );

      CREATE TEMP TABLE centroidihotspot (
        id SERIAL,
        id_voronoi_polygon INTEGER,
        st_centroid geometry
      );

      INSERT INTO centroidihotspot(id_voronoi_polygon, st_centroid) SELECT id, st_centroid(geom) FROM nearstationpolygons;

      xp := (SELECT st_x(centroidihotspot.st_centroid) FROM centroidihotspot WHERE centroidihotspot.id_voronoi_polygon = current_id_voronoi_polygon);
      yp := (SELECT st_y(centroidihotspot.st_centroid) FROM centroidihotspot WHERE centroidihotspot.id_voronoi_polygon = current_id_voronoi_polygon);


      CREATE TABLE centroid_polygon(
        id SERIAL,
        centroid_pol geometry
      );


      INSERT INTO centroid_polygon(centroid_pol) SELECT st_centroid(geom) FROM poligonistazione WHERE id_voronoi_polygon = current_id_voronoi_polygon;
      CREATE TABLE slope_table AS (SELECT st_x(centroid_polygon.centroid_pol) as x_slope , st_y(centroid_polygon.centroid_pol) AS y_slope FROM centroid_polygon);
      SELECT regr_slope(slope_table.y_slope, slope_table.x_slope) INTO slope FROM slope_table;

      RAISE NOTICE 'slope %',slope;
      SELECT (AVG(ST_Perimeter(geom)))/5 INTO line_buffer FROM poligonistazione WHERE id_voronoi_polygon = current_id_voronoi_polygon;


     -- x:= (SELECT st_x((SELECT centroid_pol FROM(SELECT centroid_polygon.centroid_pol,st_distance(centroid_polygon.centroid_pol,(SELECT geom FROM railway_stations WHERE gid = stationID)) as distance FROM centroid_polygon ORDER BY distance DESC LIMIT 1) AS massimo))) ;
      x:= 2503811;
      y:= yp + slope*(x - xp);

      INSERT INTO punti SELECT st_makepoint(x,y);

     -- x:= (SELECT st_x(railway_stations.geom) FROM railway_stations WHERE gid = stationID) ;
      x:= 2354956;
      y:= yp + slope*(x - xp);

      INSERT INTO punti SELECT st_makepoint(x,y);
      RAISE NOTICE 'line buffer  %',  line_buffer;
      IF (SELECT count(centroid_polygon.centroid_pol) FROM centroid_polygon) > 3 THEN
         INSERT INTO ret(geom, id_voronoi_polgyon) VALUES ((SELECT st_buffer(st_makeline(st_setsrid(punti.geom,3004)), line_buffer) FROM punti), current_id_voronoi_polygon);
      END IF;

    END LOOP;
	END;
$$
