create function "__nearestisoipsefinder"(stationid integer, dr integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    station RECORD;
    hazardArea geometry;
  BEGIN

   CREATE TEMP TABLE tempIsoipse (
    id SERIAL PRIMARY KEY ,
    geom GEOMETRY,
    elevation INTEGER
    );

    SELECT * INTO station FROM points WHERE gid=stationid;
    hazardArea := (SELECT ST_Buffer(station.geom, dr));

    --- intersezione tra hazardArea e Isoipse
    INSERT INTO tempIsoipse (elevation,geom) (SELECT isoipse_abruzzo_25.elevation,st_intersection(isoipse_abruzzo_25.geom,hazardArea) as geom
                         FROM isoipse_abruzzo_25 WHERE st_intersects(isoipse_abruzzo_25.geom,hazardArea));

    --- estrazione da multilineString a linestring

    INSERT INTO tempIsoipse(elevation,geom) (SELECT tempIsoipse.elevation,(st_dump(tempIsoipse.geom)).geom FROM tempIsoipse WHERE st_geometrytype(tempIsoipse.geom) = 'ST_MultiLineString') ;
    INSERT INTO tempIsoipse(elevation,geom) (SELECT tempIsoipse.elevation, st_linemerge(tempIsoipse.geom) FROM tempIsoipse WHERE st_geometrytype(tempIsoipse.geom) = 'ST_MultiLineString');
    DELETE FROM tempIsoipse WHERE st_geometrytype(tempIsoipse.geom) = 'ST_MultiLineString';


    CREATE TABLE NearestIsoipses AS SELECT * FROM tempIsoipse;

    DROP TABLE tempIsoipse;



	END;
$$;
