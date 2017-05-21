CREATE OR REPLACE FUNCTION __ZoneFragmentsFinder () RETURNS void
	LANGUAGE plpgsql
AS $$

	DECLARE
    NearestZone RECORD;
    PrimaIsoipse RECORD ;
    TempFragment RECORD;
    CurrentIsoipse RECORD;
    zoneCorrente RECORD;

  BEGIN

    CREATE TABLE ZoneFragments(
      id SERIAL PRIMARY KEY ,
      geom GEOMETRY,
      id_zone INTEGER
    );

    --- Prendo un primo poligono e interseco con le curve di livello (curve risultanti dall'intersezione con il buffer)

    FOR NearestZone IN (SELECT * FROM  nearestzones) LOOP

      CREATE TEMP TABLE TempIsoipses(
          id INTEGER,
          geom GEOMETRY,
          elevation INTEGER
        );
        CREATE TEMP TABLE TempFragments(
          id SERIAL PRIMARY KEY ,
          geom GEOMETRY,
          id_zone INTEGER
        );
          CREATE TEMP TABLE CurrentIsoipses(
          id INTEGER ,
          geom GEOMETRY,
          elevation INTEGER
        );

        SELECT * INTO zoneCorrente FROM nearestzones WHERE id = NearestZone.id;
        INSERT INTO TempIsoipses(id,geom,elevation) (SELECT nearestisoipses.id,(st_dump(st_collectionextract(st_intersection(nearestisoipses.geom,zoneCorrente.geom),2))).geom as geom,nearestisoipses.elevation FROM nearestisoipses);

        --- Prima split (popolamento temp fragment)
        SELECT * INTO PrimaIsoipse FROM (SELECT * FROM nearestisoipses WHERE (SELECT id From TempIsoipses LIMIT 1) = nearestisoipses.id) as prima;
        INSERT INTO TempFragments(geom,id_zone) (SELECT (st_dump(st_collectionextract(st_split(zoneCorrente.geom,PrimaIsoipse.geom),3))).geom , zoneCorrente.id);
        --- delete isoipse
        DELETE FROM TempIsoipses WHERE TempIsoipses.id = PrimaIsoipse.id;

        WHILE (SELECT count(*) FROM TempFragments) > 0 LOOP

          SELECT * INTO TempFragment FROM TempFragments LIMIT 1;
            INSERT INTO CurrentIsoipses(id,geom,elevation) (SELECT TempIsoipses.id,(st_dump(st_collectionextract(st_intersection(TempIsoipses.geom,TempFragment.geom),2))).geom as geom,TempIsoipses.elevation FROM TempIsoipses);
                IF (SELECT count(*) FROM CurrentIsoipses) > 0 THEN
                   SELECT * INTO CurrentIsoipse FROM (SELECT * FROM nearestisoipses WHERE (SELECT id From CurrentIsoipses LIMIT 1) = nearestisoipses.id) as currentiso;
                   INSERT INTO TempFragments(geom,id_zone) (SELECT (st_dump(st_collectionextract(st_split(TempFragment.geom,CurrentIsoipse.geom),3))).geom, zoneCorrente.id);
                   DELETE FROM TempIsoipses WHERE TempIsoipses.id = CurrentIsoipse.id;
                   DELETE FROM TempFragments WHERE TempFragments.id = TempFragment.id;
                ELSE
                  INSERT INTO ZoneFragments(geom,id_zone) VALUES (TempFragment.geom,TempFragment.id_zone);
                  DELETE FROM TempFragments WHERE TempFragments.id = TempFragment.id;
                END IF;
            TRUNCATE TABLE CurrentIsoipses;
        END LOOP;

        DROP TABLE IF EXISTS TempIsoipses;
        DROP TABLE IF EXISTS TempFragments;
        DROP TABLE IF EXISTS CurrentIsoipses;

    END LOOP ;

    DELETE FROM ZoneFragments WHERE st_area(ZoneFragments.geom) < 100;


	END;
$$
