OUTPUT_BUCKET=""
docker run -v $(pwd):/outputs -it amazonlinux /bin/bash /outputs/build.sh

aws s3 cp venv.zip s3://$OUTPUT_BUCKET/
