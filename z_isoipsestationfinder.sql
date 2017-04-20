CREATE OR REPLACE FUNCTION z_isoipsestationfinder (stationid integer) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
    station RECORD;
    bufferEsterno geometry;
  BEGIN

   CREATE TEMP TABLE tempIsoipse (
    id SERIAL PRIMARY KEY ,
    geom GEOMETRY,
    elevation INTEGER
    );

    SELECT * INTO station FROM railway_stations WHERE gid=stationid;
    bufferEsterno := (SELECT ST_Buffer(station.geom, 1100));

    INSERT INTO tempIsoipse (elevation,geom) (SELECT isoipse_abruzzo_25.elevation,st_intersection(isoipse_abruzzo_25.geom,bufferEsterno) as geom
                         FROM isoipse_abruzzo_25 WHERE st_intersects(isoipse_abruzzo_25.geom,bufferEsterno));

    INSERT INTO tempIsoipse(elevation,geom) (SELECT tempIsoipse.elevation,(st_dump(tempIsoipse.geom)).geom FROM tempIsoipse WHERE st_geometrytype(tempIsoipse.geom) = 'ST_MultiLineString') ;
    DELETE FROM tempIsoipse WHERE st_geometrytype(tempIsoipse.geom) = 'ST_MultiLineString';

    CREATE TABLE IsoipseNearStation AS SELECT * FROM tempIsoipse;


    --- SELECT st_union((SELECT geom FROM isoipsenearstation),(SELECT geom FROM isoipsenearstation)) FROM isoipsenearstation as a,isoipsenearstation as b where st_intersects(a.geom,b.geom);
    ---SELECT a.geom as geoma, b.geom as geomb FROM tempIsoipse as a, tempIsoipse as b where st_intersects(a.geom,b.geom);

    DROP TABLE tempIsoipse;



	END;
$$
