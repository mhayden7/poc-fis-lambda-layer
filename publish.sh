#!/bin/bash
project_dir=$(pwd)

echo "Install lambda python dependencies"
echo $'#########################################\n'
cd lambdas/python
if [ ! -d ".venv" ]; then
    python -m venv .venv
fi
source .venv/bin/activate
pip install --target ./package -r requirements.txt
deactivate
cd $project_dir

echo "Remove old lambda bundles"
echo $'#########################################\n'
rm *.zip
rm *.jar

echo "Bundle python lambda code"
echo $'#########################################\n'
cd lambdas/python
cd $dir/package
zip -qr "$project_dir/python.zip" .
cd ..
zip "$project_dir/python.zip" *.py
cd ..
cd $project_dir

echo "Bundle nodejs lambda code"
echo $'#########################################\n'
cd lambdas/nodejs
zip "$project_dir/nodejs.zip" *
cd ..
cd $project_dir

echo "Bundle dotnet8 lambda code"
echo $'#########################################\n'
cd lambdas/dotnet/src/dotnet
# export PATH="$PATH:/home/starlokk/.dotnet/tools"
dotnet lambda package --output-package "$project_dir/dotnet.zip"
cd $project_dir

echo "Bundle Java lambda code"
echo $'#########################################\n'
cd lambdas/java/src
mvn clean package
cp ./target/fis_java-1.0.jar $project_dir
cd $project_dir


echo "Publish Terraform"
echo $'#########################################\n'
cd ./terraform
terraform init
terraform apply
cd $project_dir