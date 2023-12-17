#!/bin/bash
#
# Creation and modification of devices with same service and subservice, but different protocol

echo "Creation and modification of devices with same service and subservice, but different protocol"

# define varibles values for test
export HOST_IOT=127.0.0.1:8080
echo "HOST_IOT $HOST_IOT  ip and port for iotagent"
export HOST_CB=127.0.0.1:1026
echo "HOST_CB $HOST_CB ip and port for CB (Context Broker)"
export SERVICE=serv22
echo "SERVICE  $SERVICE to create device"
export SRVPATH=/srf
echo "SRVPATH $SRVPATH  new service_path to create device"

#general functions
trap "exit 1" TERM
export TOP_PID=$$

declare -i number_errors=0

function assert_code()
{
res_code=` echo $res | grep -c "#code:$1"`
if [ $res_code -eq 1 ]
then
echo " OKAY"
else
echo  " ERROR: " $2
((number_errors++))
kill -s TERM $TOP_PID
fi
}

function assert_contains()
{
if [[ "$res" =~ .*"$1".* ]]
then
echo " OKAY"
else
echo  " ERROR: " $2
((number_errors++))
kill -s TERM $TOP_PID
fi

}

# TEST
echo "10- create $SERVICE  $SRVPATH  for mqtt"
res=$( curl -X POST http://$HOST_IOT/iot/services \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"services": [{ "apikey": "apikeymqtt", "token": "tokenmqtt", "cbroker": "http://10.95.213.36:1026", "entity_type": "thingmqtt", "resource": "/iot/mqtt" }]}' )
echo $res
assert_code 201 "service already exists"

echo "20-create $SERVICE  $SRVPATH  for ul20"
res=$( curl -X POST http://$HOST_IOT/iot/services \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"services": [{ "apikey": "apikeyul20", "token": "tokenul20", "cbroker": "http://10.95.213.36:1026", "entity_type": "thingul20", "resource": "/iot/d" }]}' )
echo $res
assert_code 201 "service already exists"

echo "30- create device for mqtt"
res=$( curl -X POST http://$HOST_IOT/iot/devices \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"devices":[{"device_id":"sensor_mqtt","protocol":"PDI-IoTA-MQTT-UltraLight"}]}' )
echo $res
assert_code 201 "device already exists"

echo "40- create device for ul20"
res=$( curl -X POST http://$HOST_IOT/iot/devices \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"devices":[{"device_id":"sensor_ul20","protocol":"PDI-IoTA-UltraLight"}]}' )
echo $res
assert_code 201 "device already exists"

echo "50- check type thingmqtt to iotagent"
res=$( curl -X GET http://$HOST_IOT/iot/devices/sensor_mqtt \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
echo $res
assert_code 200 "device already exists"

echo "60- check type thingmqtt to CB"

res=$( curl -X POST http://$HOST_CB/v1/queryContext \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"entities": [{ "id": "thingmqtt:sensor_mqtt", "type": "thingmqtt", "isPattern": "false" }]}' )
echo $res
assert_code 200 "device already exists"
assert_contains '{ "contextResponses" : [ { "contextElement" : { "type" : "thingmqtt", "isPattern" : "false", "id" : "thingmqtt:sensor_mqtt"' "no device in CB"

echo "70- check type thingul20"
res=$( curl -X GET http://$HOST_IOT/iot/devices/sensor_ul20 \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
echo $res
assert_code 200 "device already exists"

echo "80- check type thingul20 to CB"

res=$( curl -X POST http://$HOST_CB/v1/queryContext \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"entities": [{ "id": "thingul20:sensor_ul20", "type": "thingul20", "isPattern": "false" }]}' )
echo $res
assert_code 200 "device already exists"
assert_contains '{ "contextResponses" : [ { "contextElement" : { "type" : "thingul20", "isPattern" : "false", "id" : "thingul20:sensor_ul20"' "no device in CB"

echo "90- PUT sensor_mqtt"

res=$( curl -X PUT http://$HOST_IOT/iot/devices/sensor_mqtt \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"endpoint" : "http://10.95.213.81:1026"}' )
echo $res
assert_code 204 "device already exists"

echo "100- PUT sensor_ul20"
res=$( curl -X PUT http://$HOST_IOT/iot/devices/sensor_ul20 \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" \
-d '{"endpoint" : "http://10.95.213.81:1026"}' )
echo $res
assert_code 204 "device already exists"

echo "110- check modification in  sensor_mqtt"
res=$( curl -X GET http://$HOST_IOT/iot/devices/sensor_mqtt \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
echo $res
assert_code 200 "device already exists"

echo "130- check modification in  sensor_ul20"
res=$( curl -X GET http://$HOST_IOT/iot/devices/sensor_ul20 \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
echo $res
assert_code 200 "device already exists"

echo "150- delete service mqtt"
res=$( curl -X DELETE "http://$HOST_IOT/iot/services?resource=/iot/mqtt&device=true" \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
assert_code 204 "device already exists"


echo "160- delete service ul20"
res=$( curl -X DELETE "http://$HOST_IOT/iot/services?resource=/iot/d&device=true" \
-i -s -w "#code:%{http_code}#" \
-H "Content-Type: application/json" \
-H "Fiware-Service: $SERVICE" \
-H "Fiware-ServicePath: $SRVPATH" )
assert_code 204 "device already exists"


echo " ALL tests are OK"
