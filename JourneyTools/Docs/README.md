## Run Meteor
meteor --port 1337

## Backup Mongo DB 
mongodump -h 127.0.0.1 --port 1338 -d meteor

## Restore Mongo DB
mongorestore -h 127.0.0.1 --port 3001 -d meteor dump/meteor

## Set env urls to remote DB if desired
### export MONGO_URL="mongodb://JourneyDocs:J0urn3y1234!@c319.lighthouse.0.mongolayer.com:10319,c319.lighthouse.1.mongolayer.com:10319/JourneyDocs?replicaSet=set-5504ac361394a0278a0000cb&readPreference=primaryPreferred"
### export MONGO_OPLOG_URL="mongodb://JourneyDocs:J0urn3y1234!@c319.lighthouse.0.mongolayer.com:10319,c319.lighthouse.1.mongolayer.com:10319/local?authSource=JourneyDocs"