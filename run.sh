#!/bin/bash
echo "Experiments are started!"

export FUSEKI_HOME=/home/ubuntu/jena/apache-jena-fuseki-3.16.0
export FUSEKI_BASE=/home/ubuntu/jena/apache-jena-fuseki-3.16.0/run

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"


case $key in
    -d|--dataset)
    DATASET="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--times)
    TIMES="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--result)
    RESULTPATH=$2
    shift # past argument
    shift # past value
    ;;
    -s|--system)
    DATABASENAME="$2"
    shift # past argument
    shift # past value
    ;;
    -w|--wait)
    SLEEP="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--timeout)
    Timeout="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters




if [ $DATASET == "LUBM100k" ] 
then
	#--------------------------------------------Jena LUBM 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/100k/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /lubm100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/lubm/queries/100k/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/lubm100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K

elif [ $DATABASENAME == "Virtuoso" ]
        then

	if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
		echo "Virtuoso is running"
	else
		
	cd /home/ubuntu/vos/virtuoso-opensource/bin/
	./virtuoso-t -fd &
	
	sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
	fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<lubm100k01>" "<lubm100k02>" "<lubm100k03>" "<lubm100k04>" "<lubm100k05>" "<lubm100k06>" "<lubm100k07>" "<lubm100k08>" "<lubm100k09>" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/lubm/queries/100k/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	( java -server -Xmx40g -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("lubm100k01" "lubm100k02" "lubm100k03" "lubm100k04" "lubm100k05" "lubm100k06" "lubm100k07" "lubm100k08" "lubm100k09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/lubm/queries/100k/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5

elif [ $DATABASENAME == "roqet" ]
        then

for gname in /home/ubuntu/lubm/100k/* ;do
	(


	for k in /home/ubuntu/lubm/queries/100k/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5




elif [ $DATABASENAME == "arq" ]
        then



for gname in   /home/ubuntu/lubm/100k/*;do
	(


	for k in  /home/ubuntu/lubm/queries/100k/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches  ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5





        fi #--------------------------------------------Virtuoso LUBM 100K









elif [ $DATASET == "LUBM100m" ]
then
        #--------------------------------------------Jena LUBM 100m
        if [ $DATABASENAME == "Jena" ]
        then

for d in /home/ubuntu/jena_load/100m/* ; do
        (
        echo "running fuseki on this tdb2 db: $d"
        ls -lh "$d"
        (/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /lubm100m)  & bpid=$!

        while ! nc -z localhost 3030; do
            sleep 1
        done

        echo "Fuseki is now listening on 3030..."

        for k in /home/ubuntu/lubm/queries/100m/*; do
                (
                echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
                for i in $( seq 0 $TIMES );do(    (ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/lubm100m/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done

        echo "Fuseki PID: $bpid"
        kill -9 $bpid
        sleep 5

)done
        #fi #--------------------------------------------Jena LUBM 100m
	elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<lubm100m01>" "<lubm100m02>" "<lubm100m03>" "<lubm100m04>" "<lubm100m05>" "<lubm100m06>" "<lubm100m07>" "<lubm100m08>" "<lubm100m09>" )

for gname in ${StringArray[@]};do
	(


        for k in /home/ubuntu/lubm/queries/100m/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("lubm100m01" "lubm100m02" "lubm100m03" "lubm100m04" "lubm100m05" "lubm100m06" "lubm100m07" "lubm100m08" "lubm100m09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/lubm/queries/100m/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5

elif [ $DATABASENAME == "roqet" ]
        then

for gname in /home/ubuntu/lubm/100m/* ;do
	(


	for k in home/ubuntu/lubm/queries/100m/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5




elif [ $DATABASENAME == "arq" ]
        then



for gname in   /home/ubuntu/lubm/100m/*;do
	(


	for k in /home/ubuntu/lubm/100m/* ; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5






        fi #--------------------------------------------Virtuoso LUBM 100K





	elif [ $DATASET == "LUBM1b" ]
then
        #--------------------------------------------Jena LUBM 1B
        if [ $DATABASENAME == "Jena" ]
        then

for d in /home/ubuntu/jena_load/1b/* ; do
        (
        echo "running fuseki on this tdb2 db: $d"
        ls -lh "$d"
        (/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /lubm1b)  & bpid=$!

        while ! nc -z localhost 3030; do
            sleep 1
        done

        echo "Fuseki is now listening on 3030..."

        for k in /home/ubuntu/lubm/queries/1b/*; do
                (
                echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
                for i in $( seq 0 $TIMES );do(    (ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/lubm1b/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”; sleep $SLEEP;echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done

        echo "Fuseki PID: $bpid"
        kill -9 $bpid
        sleep 5

)done
        #fi #--------------------------------------------Jena LUBM 100m
	elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<lubm1b01>" "<lubm1b02>" "<lubm1b03>" "<lubm1b04>" "<lubm1b05>" "<lubm1b06>" "<lubm1b07>" "<lubm1b08>" "<lubm1b09>" )

for gname in ${StringArray[@]};do
	(


        for k in /home/ubuntu/lubm/queries/1b/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("lubm1b01" "lubm1b02" "lubm1b03" "lubm1b04" "lubm1b05" "lubm1b06" "lubm1b07" "lubm1b08" "lubm1b09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/lubm/queries/1b/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5






        fi #--------------------------------------------Virtuoso LUBM 100K








##################################################################################
##										##
##										##
##										##
##										##
##				FISHMARK					##


        
elif [ $DATASET == "FISHMARK" ]
then
        #--------------------------------------------Jena FISHMARK
        if [ $DATABASENAME == "Jena" ]
        then

for d in /home/ubuntu/jena_load/fish/* ; do
        (
        echo "running fuseki on this tdb2 db: $d"
        ls -lh "$d"
        (/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /fishmark)  & bpid=$!

        while ! nc -z localhost 3030; do
            sleep 1
        done

        echo "Fuseki is now listening on 3030..."

        for k in /home/ubuntu/fish/queries/*; do
                (
                echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do(    (ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/fishmark/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”; sleep $SLEEP;echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
        echo "Fuseki PID: $bpid"
        kill -9 $bpid
        sleep 5

)done
        #fi #--------------------------------------------Jena FISHMARK
	elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<fish02>" "<fish03>" "<fish04>" "<fish05>" "<fish06>" "<fish08>" "<fish09>" )

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/fish/queries/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("fish02" "fish03" "fish04" "fish05" "fish06" "fish08" "fish09"  )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/fish/queries/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done


        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5


elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/fish/fish-*;do
	(


	for k in /home/ubuntu/fish/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "arq" ]
        then



for gname in  /home/ubuntu/fish/fish-* ;do
	(


	for k in  /home/ubuntu/fish/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5








        fi #--------------------------------------------Virtuoso LUBM 100K



#fi #---------------------------FISHMARK if




##################################################################################
##										##
##										##
##										##
##										##
##				WATDIV  					##




elif [ $DATASET == "WATDIV100k" ] 
then
	#--------------------------------------------Jena Watdiv 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/watdiv/100k/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/watdiv/queries/100k/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K
	elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<watdiv100k01>" "<watdiv100k02>" "<watdiv100k03>" "<watdiv100k04>" "<watdiv100k05>" "<watdiv100k06>" "<watdiv100k07>" "<watdiv100k08>" "<watdiv100k09>")

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/watdiv/queries/100k/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server -Xmx60g  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("watdiv100k01" "watdiv100k02" "watdiv100k03" "watdiv100k04" "watdiv100k05" "watdiv100k06" "watdiv100k07" "watdiv100k08" "watdiv100k09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/watdiv/queries/100k/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5

        #fi #--------------------------------------------Virtuoso LUBM 100K

elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/watdiv/datasets/100k/*;do
	(


	for k in /home/ubuntu/watdiv/queries/100k/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "arq" ]
        then



for gname in /home/ubuntu/watdiv/datasets/100k/*  ;do
	(


	for k in /home/ubuntu/watdiv/queries/100k/* ; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5






        fi #--------------------------------------------Virtuoso LUBM 100K







elif [ $DATASET == "WATDIV10m" ] 
then
	#--------------------------------------------Jena Watdiv 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/watdiv/10m/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/watdiv/queries/100k/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K
	 elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<watdiv10m01>" "<watdiv10m02>" "<watdiv10m03>" "<watdiv10m04>" "<watdiv10m05>" "<watdiv10m06>" "<watdiv10m07>" "<watdiv10m08>" "<watdiv10m09>")

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/watdiv/queries/q*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;timeout $Timeout  ./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("watdiv10m01" "watdiv10m02" "watdiv10m03" "watdiv10m04" "watdiv10m05" "watdiv10m06" "watdiv10m07" "watdiv10m08" "watdiv10m09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/watdiv/queries/q*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5

elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/watdiv/datasets/10m/*;do
	(


	for k in /home/ubuntu/watdiv/queries/q*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "arq" ]
        then



for gname in /home/ubuntu/watdiv/datasets/10m/*  ;do
	(


	for k in /home/ubuntu/watdiv/queries/q* ; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5





        fi #--------------------------------------------Virtuoso LUBM 100K





elif [ $DATASET == "WATDIV1b" ] 
then
	#--------------------------------------------Jena Watdiv 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/watdiv/1b/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/watdiv/queries/100k/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K
	  elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<watdiv1b01>" "<watdiv1b02>" "<watdiv1b03>" "<watdiv1b04>" "<watdiv1b05>" "<watdiv1b06>" "<watdiv1b07>" "<watdiv1b08>" "<watdiv1b09>")

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/watdiv/queries/q*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;timeout $Timeout  ./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("watdiv1b01" "watdiv1b02" "watdiv1b03" "watdiv1b04" "watdiv1b05" "watdiv1b06" "watdiv1b07" "watdiv1b08" "watdiv1b09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/watdiv/queries/q*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5


elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/watdiv/datasets/1b/*;do
	(


	for k in /home/ubuntu/watdiv/queries/q*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "arq" ]
        then



for gname in /home/ubuntu/watdiv/datasets/1b/*  ;do
	(


	for k in /home/ubuntu/watdiv/queries/q* ; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5




        fi #--------------------------------------------Virtuoso LUBM 100K


#fi #-- WATDIV







#elif [ $DATASET == "WATDIV10m" ] 
#then
	#--------------------------------------------Jena Watdiv 100K
#	if [ $DATABASENAME == "Jena" ]
#	then

#for d in /home/ubuntu/jena_load/watdiv/10m/* ; do
#	(
#	echo "running fuseki on this tdb2 db: $d"
#	ls -lh "$d"
#	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!
#
#	while ! nc -z localhost 3030; do
 #           sleep 1
  #      done
#
#	echo "Fuseki is now listening on 3030..."
#	
#	for k in /home/ubuntu/watdiv/queries/100k/*; do
#		(
#		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
#		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done
#
#		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
#
#	)done
#
#	echo "Fuseki PID: $bpid"
#	kill -9 $bpid
#	sleep 5
#
#)done
#	#fi #--------------------------------------------Jena LUBM 100K
#	 elif [ $DATABASENAME == "Virtuoso" ]
#        then
#
#        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
#                echo "Virtuoso is running"
#        else
#
#        cd /home/ubuntu/vos/virtuoso-opensource/bin/
#        ./virtuoso-t -fd &
##
#        sleep 5
#        echo "Waiting to launch Virtuoso (isql) on 1111..."
#
#        while ! nc -z localhost 1111; do
#            sleep 5
#        done
#        echo "Virtuoso (isql) launch on 1111..."
#        fi
#
##sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
#declare -a StringArray=("<watdiv10m01>" "<watdiv10m02>" "<watdiv10m03>" "<watdiv10m04>" "<watdiv10m05>" "<watdiv10m06>" "<watdiv10m07>" "<watdiv10m08>" "<watdiv10m09>")

#for gname in ${StringArray[@]};do
 #       (
#
#
#        for k in /home/ubuntu/watdiv/queries/q*; do
#                (
#                echo "" > $RESULTPATH/$gname.${k##*/}
#                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;timeout $Timeout  ./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done
#
#                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'
#
#        )done
#        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'
#
#        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5


#       fi #--------------------------------------------Virtuoso LUBM 100K





elif [ $DATASET == "SP2B100m" ] 
then
	#--------------------------------------------Jena Watdiv 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/sp2/100m/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; timeout $Timeout /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K
	  elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<sp2bench100m01>" "<sp2bench100m02>" "<sp2bench100m03>" "<sp2bench100m04>" "<sp2bench100m05>" "<sp2bench100m06>" "<sp2bench100m07>" "<sp2bench100m08>" "<sp2bench100m09>")

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/sp2bench/queries/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;timeout $Timeout  ./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server -Xmx40g  -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("sp2b100m01" "sp2b100m02" "sp2b100m03" "sp2b100m04" "sp2b100m05" "sp2b100m06" "sp2b100m07" "sp2b100m08" "sp2b100m09" )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5


elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/sp2bench/dataset/sp2100m*;do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5


elif [ $DATABASENAME == "arq" ]
        then



for gname in /home/ubuntu/sp2bench/dataset/sp2100m*;do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5




        fi #--------------------------------------------Virtuoso LUBM 100K









elif [ $DATASET == "SP2B100k" ] 
then
	#--------------------------------------------Jena Watdiv 100K
	if [ $DATABASENAME == "Jena" ]
	then

for d in /home/ubuntu/jena_load/sp2/100k/* ; do
	(
	echo "running fuseki on this tdb2 db: $d"
	ls -lh "$d"
	(/home/ubuntu/jena/apache-jena-fuseki-3.16.0/fuseki-server  --loc "$d" /watdiv100k)  & bpid=$!

	while ! nc -z localhost 3030; do
            sleep 1
        done

	echo "Fuseki is now listening on 3030..."
	
	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > "$RESULTPATH/${d##*/}.${k##*/}"
		for i in $( seq 0 $TIMES );do( 	(ts=$(date +%s%N) ; timeout $Timeout /home/ubuntu/jena/apache-jena-fuseki-3.16.0/bin/s-query --service=http://127.0.0.1:3030/watdiv100k/query --query="$k" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> "$RESULTPATH/${d##*/}.${k##*/}";))done

		echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

	)done

	echo "Fuseki PID: $bpid"
	kill -9 $bpid
	sleep 5

)done
	#fi #--------------------------------------------Jena LUBM 100K
	  elif [ $DATABASENAME == "Virtuoso" ]
        then

        if lsof -Pi :1111 -sTCP:LISTEN -t >/dev/null ; then
                echo "Virtuoso is running"
        else

        cd /home/ubuntu/vos/virtuoso-opensource/bin/
        ./virtuoso-t -fd &

        sleep 5
        echo "Waiting to launch Virtuoso (isql) on 1111..."

        while ! nc -z localhost 1111; do
            sleep 5
        done
        echo "Virtuoso (isql) launch on 1111..."
        fi

#sparql define input:default-graph-uri <watdiv1b01> select * where {?s ?p ?o} limit 2 ;
declare -a StringArray=("<sp2bench100k02>" "<sp2bench100k03>" "<sp2bench100k04>" "<sp2bench100k05>"  )

for gname in ${StringArray[@]};do
        (


        for k in /home/ubuntu/sp2bench/queries/*; do
                (
                echo "" > $RESULTPATH/$gname.${k##*/}
                for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N) ; sparql_query=$(head -1 $k) ;cd /home/ubuntu/vos/virtuoso-opensource/bin/;timeout $Timeout  ./isql 1111 dba dba exec="sparql define input:default-graph-uri $gname $sparql_query;" ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        echo 3 > /proc/sys/vm/drop_caches ;  printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
        #echo "Virtuoso PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "Blazegraph" ]
        then

	if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null ; then
		echo " zegraphis running"
	else
		
	cd /home/ubuntu/blazegraph
	(java -server -Xmx40g -jar blazegraph.jar &) & bpid=$!
	
	sleep 5
        echo "Waiting to launch Blazegraph on 9999..."

        while ! nc -z localhost 9999; do
            sleep 5
        done
        echo "Blazegraph launched on 9999..."
	fi

declare -a StringArray=("sp2b100k02" "sp2b100k03" "sp2b100k04" "sp2b100k05"  )

for gname in ${StringArray[@]};do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/$gname.${k##*/}
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);sparql_query=$(head -1 $k) ;timeout $Timeout curl -X POST http://127.0.0.1:9999/blazegraph/namespace/$gname/sparql --data-urlencode 'query='"$sparql_query"''  -H 'Accept:application/rdf+xml' ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/$gname.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        echo "Blazegraph PID: $bpid"
        kill -9 $bpid
        sleep 5

elif [ $DATABASENAME == "roqet" ]
        then



for gname in /home/ubuntu/sp2bench/dataset/sp2b100k*;do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout roqet -i sparql  $k  -D $gname ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5

elif [ $DATABASENAME == "arq" ]
        then



for gname in /home/ubuntu/sp2bench/dataset/sp2b100k*;do
	(


	for k in /home/ubuntu/sp2bench/queries/*; do
		(
		echo "" > $RESULTPATH/${gname##*/}.${k##*/} 
		for i in $( seq 0 $TIMES );do(  (ts=$(date +%s%N);timeout $Timeout /home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data $gname --query $k ; tt=$((($(date +%s%N) - $ts)/1000000)) ; echo “Fuseki for  $k  Time taken: $tt milliseconds”;sleep $SLEEP; echo "$tt" >> $RESULTPATH/${gname##*/}.${k##*/};))done

                echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'

        )done
	echo 3 > /proc/sys/vm/drop_caches ; swapoff -a ; printf '\n%s\n' 'Ram-cache and Swap Cleared'
	)done
        #echo "Blazegraph PID: $bpid"
        #kill -9 $bpid
        #sleep 5




#/home/ubuntu/jena/apache-jena-3.16.0/bin/arq --data ~/sp2bench/dataset/sp2b100k-02-025-0.nt --query ~/sp2bench/queries/q1.rq

#roqet -i sparql  ~/sp2bench/q1.rq  -D ~/sp2bench/sp2-nt-sort/sp2b100k-sorted.nt


        fi #--------------------------------------------Virtuoso LUBM 100K









fi #-- WATDIV





















