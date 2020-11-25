# CIDR
CIDR: Classroom Interaction Detection and Recognition System. 
Process first-person video recordings in a preschool classroom to detect interactions with teachers and peers, as well as decoding child-directed speech. As detailed in the paper "Automatized analysis of children’s exposure to child-directed speech in reschool settings: Validation and application." https://doi.org/10.1371/journal.pone.0242511

PROTOCOL:

1.	Extract audio from video as mono 16-bit PCM, 32 kHz using Audacity (install FFmpeg) or Matlab’s audioread function
2.	Manually extract video frames containing faces to build face collection. We employed VFC. Every person interacting with the focal child must appear at least once in the selected frames. Follow AWS recommendations at: https://docs.aws.amazon.com/rekognition/latest/dg/recommendations-facial-input-images.html
3.	Upload images for face collections, videos, and audio to AWS S3 buckets. 
4.	Create Face collection using "AWSCollecCreate.py"
5.	Add each image to the face collection created in step 4) using "AWSCollecAdd.py"
6.	Explore detected faces in step 5) and assign the project’s ID to each face using "FaceCollectionIDCheck.m". Delete low-quality faces first using "AWSCollecDeleteFaces.py" and later using the commented section at the end of "FaceCollectionIDCheck.m"
7.	Use "AWSCollecListFaces.py" to generate final list and save as a json file
8.	Append project’s ID employed in the study to the List of faces from step 7) using "TrueIDAppend.m"
9.	Run "AWSGetFaceDetec.py", "AWSGetFaceSearch.py" and save json output in their corresponding folders
10.	Check identification from FaceSearch using "IdentificationCheck.m"
11.	Process output from FaceDetect and FaceSearch using "VideoFeatureExtraction.m"
12.	Obtain audio transcription using "AWSTranscribe.py".
13.	Process transcripts and audio using "AudioFeatureExtraction.m"
14.	Train classifier using “TrainClassifier.m”
15.	Deploy classifier using “DeployClassifier.m”
