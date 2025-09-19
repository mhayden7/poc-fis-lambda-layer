# poc-fis-lambda-layer
Test the AWS-provided FIS layer for lambda with several different lambda runtimes.

# Requirements
- python 3
- dotnet
- terraform
- aws cli

# Deployment
create the env-config file: ```cp terraform/env-config.yaml.template``` \
Update the 'account' and 'region' parameters.\
Set your AWS creds in your CLI. \
Execute the publish.sh script.

# Usage/Testing
The default template provided will cause 100% failure of the example lambdas for 3 minutes.
> [!WARNING]
> If you have other lambdas in your account with the tag "project: FIS", they may be selected as part of the experiment! \

Go to the FIS console, 'Expirement Templates'. Select the 'poc-fis-lambda-layer' template, the select 'Start experiment'. You will be prompted to confirm.

Now in your CLI, start the tester script. This will run for the seconds indicated in the parameter. \
```project_files/test_client.sh 300```

[It will take up to 60 seconds for the aws FIS layer in the lambdas to detect that the experiment has started](https://docs.aws.amazon.com/fis/latest/userguide/use-lambda-actions.html#understanding-polling), so you may see success for several iterations until it takes effect. You may see similar behaviour as the experiment ends. The failure injection will not *perfectly* coincide with the beginning and ending of the experiment.

## Interesting things to try:
In the FIS console, select the experiment template and 'Actions > Update experiment template'. In the 'Specify actions and targets' section you can manipulate the behavior. You can have it fail only a selected percentage of invocations instead of total failure for example, or change the action type to 'aws:lambda:invocation-add-delay' to simulate slowness/lag in your application. 