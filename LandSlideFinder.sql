CREATE OR REPLACE FUNCTION __LandSlideFinder (stationid integer, dr INTEGER) RETURNS void
	LANGUAGE plpgsql
AS $$
	DECLARE
		LandSlide_var RECORD;
		BuildingBuffer geometry;
  BEGIN

		 CREATE TABLE LandSlide (
      id SERIAL,
      geom geometry,
      id_zone INTEGER
    );

		CREATE TABLE LandSlideZones (
			id INTEGER,
			geom geometry,
			szk FLOAT
		);

		SELECT st_buffer(geom, dr) INTO BuildingBuffer FROM points WHERE gid = stationid;

		FOR LandSlide_var IN (SELECT * FROM linearregression) LOOP
			IF st_intersects(BuildingBuffer, LandSlide_var.geom) THEN
				INSERT INTO LandSlide (geom, id_zone) VALUES (LandSlide_var.geom, LandSlide_var.id_zone);
				INSERT INTO LandSlideZones (SELECT id, geom, szk FROM nearestzones WHERE id = LandSlide_var.id_zone);
			END IF;
		END LOOP;

	END;
$$
