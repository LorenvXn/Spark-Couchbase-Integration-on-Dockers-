# Spark-Couchbase-Integration-on-Dockers-

<i> Soon - some kewl Spark Streaming & Couchbase example ... but for now, setting up the environment and testing some Scala code ... Make sure you have dem gigs and rams!  </i>

[Environment setup]

- Run perl script ``couchy.pl`` to create couchbase container.

- Run perl script ``sparkling.pl`` to create Spark Container.


After running the script for Spark, you will be prompted to ``bash-4.1#``

Start Spark Shell, with Couchbase connector ``com.couchbase.client:spark-connector_2.10:1.0.0``

```
bash-4.1#spark-shell--master yarn-client --packages com.couchbase.client:spark-connector_2.10:1.0.0

[=======snip=======]

Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.6.0
      /_/

[=======snip=======]

scala>
scala>
```

3) Make sure Spark and Couchbase are in the same network - create a new bridge and add containers to it:
```
root@tron# docker network create --driver=bridge couchspark
root@tron# root@tron:/opt/couchbase/wildtest# docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
4c7f7dc3e206        bridge              bridge              local
a51cb1accae3        couchspark          bridge              local

root@tron# docker network connect couchspark fcfb352c7815
root@tron# docker network connect couchspark e61e42e5b2b8

```

Inspect bridge, and check if the containers can ping each other:
<i> Some bash kung-fu to help you with finding the IPs </i>

```
root@tron# docker inspect $(docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep spark) | grep IPAddress |  awk 'NR==2 {print $NF}' | cut -f1 -d ','
"172.17.0.2"
root@tron# docker inspect $(docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep couchbase) | grep IPAddress |  awk 'NR==2 {print $NF}' | cut -f1 -d ','
"172.17.0.3"
```

Check the IPs they are having, when inspecting the brigde - we will use this IP 172.19.0.3 for accessing the Couchbase
from Spark
```
root@tron#docker network inspect couchspark 

[=======snip=======]

        "Containers": {
            "e61e42e5b2b8eb23b2b1bedd85e37157b7aeed5b021ec77e319f02849af95d43": {
                "Name": "hahaa",
                "EndpointID": "63778e3bd160b656daf350ea04af3ccd4c5e12e4de10dc9332e1de854e48f002",
                "MacAddress": "02:42:ac:13:00:03",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            },
            "fcfb352c78152c66ce3069d39d59550a43172.19.0.3a0115cc46f5b390100bc8427f3ba04": {
                "Name": "sharp_minsky",
                "EndpointID": "695de0b18bb703c029b1c492106c69cce32ccfc91f7fe1d4cc598e37427a3578",
                "MacAddress": "02:42:ac:13:00:02",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }

```

Now, in the Spark container, run the following Scala lines from spark-shell, to check if the environment has been set-up properly:

<i> Bucket beer-sample will be used as example</i>
```

import org.apache.spark._  
import com.couchbase.spark.sql._
import com.couchbase.spark._
import org.apache.spark.sql.sources.EqualTo
import org.apache.spark.sql._


 val sparkConf = new SparkConf().setAppName("NananaaBatmanAndCouchbase!")
                .setMaster("local[*]")
                .set("com.couchbase.bucket.beer-sample", "")
                .set("com.couchbase.nodes", "172.19.0.3")

val ssc = new SparkContext(sparkConf)

sql1=SQLContext(ssc)

val beers = sql1.read.couchbase(schemaFilter=EqualTo("type", "beer"))

```

If no errors so far, still from spark-shell, you can check if you actually have access to the bucket:
```
scala> beers.printSchema()
root
 |-- META_ID: string (nullable = true)
 |-- abv: double (nullable = true)
 |-- brewery_id: string (nullable = true)
 |-- category: string (nullable = true)
 |-- description: string (nullable = true)
 |-- ibu: long (nullable = true)
 |-- name: string (nullable = true)
 |-- srm: double (nullable = true)
 |-- style: string (nullable = true)
 |-- type: string (nullable = true)
 |-- upc: long (nullable = true)
 |-- updated: string (nullable = true)
```

and let's select some beers...  

```

scala> beers.select("brewery_id", "description", "name").show()

[=======snip=======]


+--------------------+--------------------+--------------------+
|          brewery_id|         description|                name|
+--------------------+--------------------+--------------------+
|21st_amendment_br...|Deep golden color...|             21A IPA|
|21st_amendment_br...|Deep black color,...|           563 Stout|
|21st_amendment_br...|Rich golden hue c...|  Amendment Pale Ale|
|21st_amendment_br...|An American sessi...|     Bitter American|
|21st_amendment_br...|Deep, golden, ric...|  Double Trouble IPA|
|21st_amendment_br...|Deep toffee color...|General Pippo's P...|
|21st_amendment_br...|Deep amber color....|      North Star Red|
|21st_amendment_br...|Deep black color....|Oyster Point Oyst...|
|21st_amendment_br...|Traditional Engli...|         Potrero ESB|
|21st_amendment_br...|Light golden colo...|   South Park Blonde|
|21st_amendment_br...|The definition of...|    Watermelon Wheat|
|3_fonteinen_brouw...|                    |Drie Fonteinen Kriek|
|3_fonteinen_brouw...|                    |          Oude Geuze|
| 512_brewing_company|(512) ALT is a Ge...|           (512) ALT|
| 512_brewing_company|At once cuddly an...|         (512) Bruin|
| 512_brewing_company|(512) India Pale ...|           (512) IPA|
| 512_brewing_company|With Organic 2-ro...|          (512) Pale|
| 512_brewing_company|Nearly black in c...|  (512) Pecan Porter|
| 512_brewing_company|Our first barrel ...|(512) Whiskey Bar...|
| 512_brewing_company|Made in the style...|           (512) Wit|
+--------------------+--------------------+--------------------+
only showing top 20 rows

```

You can check from cbq (Couchbase container), and see if results correspond:

```
root@tron:# docker exec -ti e61e42e5b2b8 /bin/bash
root@e61e42e5b2b8:/# cbq
 No input credentials. In order to connect to a server with authentication, please provide credentials.
 Connected to : http://localhost:8091/. Type Ctrl-D or \QUIT to exit.

 Path to history file for the shell : /root/.cbq_history 
cbq> 
cbq> SELECT `brewery_id`,`description`,`name` FROM `beer-sample` WHERE  `type` = 'beer'; 

[====and some long and painful output from here on=====]

```

Environment successfully implemented!

For the next time, we will find some usefulness for com.couchbase.spark.streaming._ 

From our spark Container:

```
scala> import com.couchbase.spark.streaming._
import com.couchbase.spark.streaming._
```

But first thing first, we gon' do some replication: [Couchbase replication to Elasticsearch, and Spark]https://github.com/Satanette/Couchbase-replication-to-ElasticSearch-and-Spark 

