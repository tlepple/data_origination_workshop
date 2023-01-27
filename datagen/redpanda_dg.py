import time
from faker import Faker
from datagenerator import DataGenerator
import simplejson as json
import sys
from kafka import KafkaProducer

#########################################################################################
#       Define variables
#########################################################################################
dg = DataGenerator()
fake = Faker() # <--- Don't Forgot this
startKey = int(sys.argv[1])
iterateVal = int(sys.argv[2])
stopVal = int(sys.argv[3])

# functions to display errors
def myconverter(obj):
    if isinstance(obj, (datetime.datetime)):
                return obj.__str__()

def encode_complex(obj):
    if isinstance(obj, complex):
        return [ojb.real, obj.imag]
    raise TypeError(repr(obj) + " is not JSON serializable")

# Messages will be serialized as JSON
def my_serializer(message):
    return json.dumps(message).encode('utf-8')


#producer = KafkaProducer(bootstrap_servers="localhost:9092",value_serializer=lambda v: simplejson.dumps(v, default=myconverter).encode('utf-8'))
#producer = KafkaProducer(bootstrap_servers="localhost:9092",value_serializer=lambda v: json.dumps(v, default=encode_complex).encode('utf-8'))
#producer = KafkaProducer(bootstrap_servers="localhost:9092",value_serializer=lambda v: json.dumps(v).encode('utf-8'))
producer = KafkaProducer(bootstrap_servers="localhost:9092",value_serializer=my_serializer)

#########################################################################################
#       Code execution below
#########################################################################################
for i in range(stopVal):
        fpg = dg.fake_person_generator(startKey, iterateVal, fake)
        for person in fpg:
                #print(json.dumps(person, ensure_ascii=False, default = myconverter))
                #print("\n")
                data = json.dumps(person, default = encode_complex)
                print(data)
                #print ("dataVarType", type(data))
                # convert json string to dict obj
                dictData = json.loads(data)
                producer.send('dgCustomer', dictData)
                #print("\n")
        producer.flush()
        print("Customer Done.")
        print('\n')
        txn = dg.fake_txn_generator(startKey, iterateVal, fake)
        for tranx in txn:
                #print(json.dumps(tranx, ensure_ascii=False, default = myconverter))
                txnData = json.dumps(tranx, default = encode_complex)
                print(txnData)
                producer.send('dgTxn', tranx)
        producer.flush()
        print("Transaction Done.")
        print('\n')
# increment and sleep
        startKey += iterateVal
        time.sleep(2)
