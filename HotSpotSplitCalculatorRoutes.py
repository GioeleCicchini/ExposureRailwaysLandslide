import psycopg2
import os
import time
# Try to connect


numeroTuple = 10
media = 0
try:

    conn=psycopg2.connect("dbname='prova' user='daniel687' password='cippalippa'")

except:
    print("I am unable to connect to the database.")

cur = conn.cursor()
TempoStimato = 0;
id = range (1,numeroTuple)

for count in id:

    percentuale = count/numeroTuple * 100
    print("Completamento ",round(percentuale,3), "%", "Tempo Stimato :",round(TempoStimato/60,3), " Minuti", "quaryfatte", count )

    try:
        startTime = time.time();
        quary = "SELECT __exposure_routes(" + str(count) + ")"
        cur.execute(quary)
        conn.commit()
        endTime = time.time()

        diff = (endTime - startTime )
        if diff > 0.1:
            TempoStimato = diff * (numeroTuple - count)
    except:
        print("z_exposure failed")




