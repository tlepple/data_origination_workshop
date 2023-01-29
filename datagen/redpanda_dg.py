import time
from faker import Faker
from datagenerator import DataGenerator
import simplejson as json
#import sys
import argparse

from kafka import KafkaProducer

#########################################################################################
#       Define variables
#########################################################################################
dg = DataGenerator()
fake = Faker() # <--- Don't Forgot this

#startKey = int(sys.argv[1])
#iterateVal = int(sys.argv[2])
#stopVal = int(sys.argv[3])
parser = argparse.ArgumentParser()

# define our required arguments to pass in:
parser.add_argument("startingCustomerID", help="Enter int value to assign to the first customerID field", type=int)
parser.add_argument("recordCount", help="Enter int value for desired number of records per group", type=int)
parser.add_argument("loopCount", help="Enter int value for iteration count", type=int)

# parse these args
args = parser.parse_args()

# assign args to vars:
startKey = int(args.startingCustomerID)
iterateVal =  int(args.recordCount)
stopVal = int(args.loopCount)

# Define some functions:
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

#  define variable for our producer
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

