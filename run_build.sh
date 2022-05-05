BUCKET_NAME=""
docker run -v $(pwd):/outputs -it amazonlinux /bin/bash /outputs/build.sh

aws s3 cp venv.zip s3://$BUCKET_NAME/
