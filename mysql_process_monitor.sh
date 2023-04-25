#!/bin/bash
# Script to Monitor MySQL process list across a host of servers
# Addy Clement, 2019 


MYSQL_USER=$mysql_usr
MYSQL_PASSWORD=$mysql_pwd
MYSQL_HOST=$mysql_host
DB_NAME=$db_name

#generic user account for all added mysql hosts
MONIT_USER=$db_user
MONIT_PASSWORD=$db_pwd

#DBS To be monitored

#declare a host array
# replace with a JSON Array of host, dbid, max conn etc to save fetching these from remote database
#thats one round trip saved  


hosts=(host1 
host2
host3
host4
host5
host6
)

connections=(110
350
320
900
450
300
)

dbcode=(portal 
Echannel
Shipping
OrdersSvc
PaymnetGateway
ReturnsSvc
)

#begin outer loop
  i=0
  while [ $i -lt ${#hosts[*]} ]; do
  echo ${hosts[$i]}

        # inner loop begins here

        mysql -u$MONIT_USER -h${hosts[$i]} -p$MONIT_PASSWORD -s -N -e "SELECT 'Statistics', (SELECT  COUNT(*) 'TotalConns'  FROM  information_schema.PROCESSLIST) 'TotalConns',
(SELECT  COUNT(*) FROM  information_schema.PROCESSLIST WHERE COMMAND NOT IN ('Sleep','Binlog Dump') AND USER <> 'system user') 'ActiveConns' ,
(SELECT  MAX(TIME) FROM  information_schema.PROCESSLIST WHERE COMMAND NOT IN ('Sleep','Binlog Dump') AND USER <> 'system user') 'MAXTimeActive',
(SELECT  AVG(TIME) FROM  information_schema.PROCESSLIST WHERE COMMAND NOT IN ('Sleep','Binlog Dump') AND USER <> 'system user') 'AverageTimeActive',
(SELECT  CONCAT (USER, '---', INFO) 'TopQuery'  FROM  information_schema.PROCESSLIST WHERE COMMAND NOT IN ('Sleep','Binlog Dump')
AND USER NOT IN ('system user', 'dbmonitusr') ORDER BY TIME DESC LIMIT 1) 'TopQuery'  ;" | while read Statistics TotalConns  ActiveConns MAXTimeActive AverageTimeActive TopQuery; do

 echo $TotalConns
        echo $ActiveConns
        echo $MAXTimeActive
        echo $AverageTimeActive
        echo $TopQuery
        query2=$(echo "$TopQuery" | sed s/"'"/"\\\'"/g)

        mysql -u$MYSQL_USER -h$MYSQL_HOST -p$MYSQL_PASSWORD -e "INSERT INTO dbname.logtable(dbcode, totalconn, activeconn, maxtime, avgtime, online , TopQuery) VALUES ('${dbcode[$i]}', '$TotalConns', $ActiveConns, $MAXTimeActive, $AverageTimeActive, 'Y' , '$query2'); "

    #Alert the team if total connection exceeds threshold
		
     
	if [ $TotalConns -gt ${connections[$i]} ]
		then #Inner Loop ends here
		echo "Total Connections on " ${hosts[$i]} " is now " $TotalConns
		   # move to d next item
  echo "Total Connections on " ${hosts[$i]} " is now " $TotalConns | mailx -v -r "monitoringuser@example.com" -s "Connection Limit Check" -S smtp="10.x.x.x:25" -S smtp-auth=login -S smtp-auth-user=$smtp_user -S smtp-auth-password=$smtp_pwd -S ssl-verify=ignore monitoringuser@example.com

       fi
      done

       i=$(( $i + 1));
  
       done
	
#End of outter loop
