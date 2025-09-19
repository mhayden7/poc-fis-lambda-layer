DURATION=$1
echo "Running test for $DURATION seconds."

while [ $SECONDS -lt $DURATION ]; do
    response=$(aws lambda invoke --function-name fis_python --payload '{"testevent": "1"}' --output json --cli-binary-format raw-in-base64-out /dev/stdout)
    echo "$response"
    response=$(aws lambda invoke --function-name fis_nodejs --payload '{"testevent": "1"}' --output json --cli-binary-format raw-in-base64-out /dev/stdout)
    echo "$response"
    response=$(aws lambda invoke --function-name fis_dotnet --payload '{"testevent": "1"}' --output json --cli-binary-format raw-in-base64-out /dev/stdout)
    echo "$response"
    sleep 5
done
