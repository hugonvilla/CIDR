from __future__ import print_function
import time
import boto3
transcribe = boto3.client('transcribe')
job_name = "C19P19AUN10"
job_uri = "https://audiobucketdata.s3.us-east-2.amazonaws.com/19_022818_Afternoon_Part 5.wav"
transcribe.start_transcription_job(
    TranscriptionJobName=job_name,
    Media={'MediaFileUri': job_uri},
    MediaFormat='wav',
    LanguageCode='en-US',
    MediaSampleRateHertz= 32000,
    OutputBucketName='audiobucketdata',
    Settings={'MaxSpeakerLabels': 10,'ShowSpeakerLabels': True}
)
while True:
    status = transcribe.get_transcription_job(TranscriptionJobName=job_name)
    if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
        break
    print("Not ready yet...")
    time.sleep(5)
print(status) 