import json
import boto3
import os
from confluent_kafka import Consumer

if __name__ == "__main__":
    session = boto3.Session(region_name=os.environ.get('AWS_STREAM_REGION'))
    kinesis = session.client('firehose')
    consumer = Consumer(
        {'bootstrap.servers': os.environ["BOOTSTRAP_SERVER"],
            'group.id': "example",
            'auto.offset.reset': 'smallest'}
    )
    consumer.subscribe([os.environ["KAFKA_TOPIC"]])

    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                # No message available within timeout.
                # Initial message consumption may take up to
                # `session.timeout.ms` for the consumer group to
                # rebalance and start consuming
                print("Waiting for message or event/error in poll()")
                continue
            elif msg.error():
                print('error: {}'.format(msg.error()))
            else:
                # Check for Kafka message
                record_value = msg.value()
                print('data: ' + str(record_value))
                print('======\n')
                try:
                    textData = record_value.decode('utf8')
                    print('Converted bytes to string: ' + textData)
                    try:
                        jdata = json.loads(textData)
                        print('Converted string to json: ' + str(jdata))
                        response = kinesis.put_record(
                             DeliveryStreamName=os.environ.get("AWS_STREAM_NAME"),
                             Record={
                                 'Data': json.dumps(jdata)
                             })
                        print("Response from Kinesis: " + str(response))
                    except Exception as e:
                        print(e)
                except:
                    print("error decoding and packaging message for kinesis")

    except KeyboardInterrupt:
        pass
    finally:
        # Leave group and commit final offsets
        consumer.close()