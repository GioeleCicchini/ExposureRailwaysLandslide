create function "__bufferedlinearregressionfinder"(stationid integer, pdiv double precision) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    x DOUBLE PRECISION;
    y DOUBLE PRECISION;
    xp DOUBLE PRECISION;
    yp DOUBLE PRECISION;
    slope DOUBLE PRECISION;
    id_zone_var INTEGER;
    line_buffer_size FLOAT;
  BEGIN

    CREATE TABLE BufferedLinearRegression (
      id SERIAL,
      geom geometry,
      id_zone INTEGER
    );

    FOR id_zone_var IN SELECT id FROM nearestzones LOOP


      DROP TABLE IF EXISTS point;
      DROP TABLE IF EXISTS Centroid_zone;
      DROP TABLE IF EXISTS slope_table;
      DROP TABLE IF EXISTS centroid_zoneFragments;



      CREATE TEMP TABLE point(
        geom GEOMETRY
      );

      CREATE TEMP TABLE Centroid_zone (
        id SERIAL,
        id_zone INTEGER,
        st_centroid geometry
      );

      INSERT INTO Centroid_zone(id_zone, st_centroid) SELECT id, st_centroid(nearestzones.geom) FROM nearestzones;

      xp := (SELECT st_x(Centroid_zone.st_centroid) FROM Centroid_zone WHERE Centroid_zone.id_zone = id_zone_var);
      yp := (SELECT st_y(Centroid_zone.st_centroid) FROM Centroid_zone WHERE Centroid_zone.id_zone = id_zone_var);


      CREATE TEMP TABLE centroid_zoneFragments(
        id SERIAL,
        centroid_fragments geometry
      );

      INSERT INTO centroid_zoneFragments(centroid_fragments) SELECT st_centroid(geom) FROM zonefragments WHERE id_zone = id_zone_var;
      CREATE TABLE slope_table AS (SELECT st_x(centroid_zoneFragments.centroid_fragments) as x_slope , st_y(centroid_zoneFragments.centroid_fragments) AS y_slope FROM centroid_zoneFragments);
      SELECT regr_slope(slope_table.y_slope, slope_table.x_slope) INTO slope FROM slope_table;

      --SELECT (AVG(ST_Perimeter(geom)))/pdiv INTO line_buffer_size FROM zonefragments WHERE id_zone = id_zone_var;

      SELECT (ST_Perimeter(geom))/pdiv INTO line_buffer_size FROM nearestzones WHERE id = id_zone_var;

      x:= 2503811;
      y:= yp + slope*(x - xp);

      INSERT INTO point SELECT st_makepoint(x,y);

      x:= 2354956;
      y:= yp + slope*(x - xp);

      INSERT INTO point SELECT st_makepoint(x,y);

      IF (SELECT count(centroid_zoneFragments.centroid_fragments) FROM centroid_zoneFragments) > 3 THEN
         INSERT INTO BufferedLinearRegression(geom, id_zone) VALUES ((SELECT st_buffer(st_makeline(st_setsrid(point.geom,3004)), line_buffer_size) FROM point), id_zone_var);
      END IF;



    END LOOP;


	END;
$$;
