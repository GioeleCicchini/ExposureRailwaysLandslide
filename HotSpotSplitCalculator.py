import psycopg2
import os
import time
# Try to connect

clear = lambda: os.system('cls')
numeroTuple = 115
media = 0
try:
    conn=psycopg2.connect("dbname='AbruzzoGeoSpatial' user='postgres' password='af54c1daa'")
except:
    print("I am unable to connect to the database.")

cur = conn.cursor()
TempoStimato = 0;
id = range (1,numeroTuple)

for count in id:
    clear()

    percentuale = count/numeroTuple * 100
    print("Completamento ",round(percentuale,3), "%", "Tempo Stimato :",round(TempoStimato/60,3), " Minuti", "quaryfatte", count )

    try:
        startTime = time.time();
        quary = "SELECT __exposure(" + str(count) + ")"
        cur.execute(quary)
        conn.commit()
        endTime = time.time()

        diff = (endTime - startTime )
        if diff > 0.1:
            TempoStimato = diff * (numeroTuple - count)
    except:
        print("z_exposure failed")




