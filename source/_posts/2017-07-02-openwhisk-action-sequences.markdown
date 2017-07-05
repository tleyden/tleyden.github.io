---
layout: post
title: "OpenWhisk Action Sequences"
date: 2017-07-02 11:30
comments: true
categories: openwhisk serverless 
---


This will walk you through getting up and running from scratch with Apache OpenWhisk on OSX, and setting up an Action Sequence where the output of one OpenWhisk Action is fed into the input of the next Action.

## Install OpenWhisk via Vagrant

```
# Clone openwhisk
git clone --depth=1 https://github.com/apache/incubator-openwhisk.git openwhisk

# Change directory to tools/vagrant
cd openwhisk/tools/vagrant

# Run script to create vm and run hello action
./hello
```

You should see reams of output, followed by:

```
==> default: ++ wsk action invoke /whisk.system/utils/echo -p message hello --result
==> default: {
==> default:     "message": "hello"
==> default: }
```

## SSH into Vagrant machine and run OpenWhisk CLI

```
$ vagrant ssh
```

Now you can access the OpenWhisk CLI:

```
$ wsk

        ____      ___                   _    _ _     _     _
       /\   \    / _ \ _ __   ___ _ __ | |  | | |__ (_)___| | __
  /\  /__\   \  | | | | '_ \ / _ \ '_ \| |  | | '_ \| / __| |/ /
 /  \____ \  /  | |_| | |_) |  __/ | | | |/\| | | | | \__ \   <
 \   \  /  \/    \___/| .__/ \___|_| |_|__/\__|_| |_|_|___/_|\_\
  \___\/ tm           |_|

Usage:
  wsk [command]
```

Re-run the "Hello world" via:

```
$ wsk action invoke /whisk.system/utils/echo -p message hello --result
{
    "message": "hello"
}
```

## Hello Go/Docker 

I tried following the [instructions on James Thomas' blog](http://jamesthom.as/blog/2017/01/17/openwhisk-and-go/) for running Go within Docker, but ran into an error (see Disqus comment), and so here's how I worked around it.

First create a simple Go program and cross compile it.  Save the following to `exec.go`:

```
package main

import "encoding/json"
import "fmt"
import "os"

func main() {
  // native actions receive one argument, the JSON object as a string
  arg := os.Args[1]

  // unmarshal the string to a JSON object
  var obj map[string]interface{}
  json.Unmarshal([]byte(arg), &obj)
  name, ok := obj["name"].(string)
  if !ok {
      name = "Stranger"
  }
  msg := map[string]string{"msg": ("Hello, " + name + "!")}
  res, _ := json.Marshal(msg)
  fmt.Println(string(res))
}
```

Cross compile it for Linux:

```
env GOOS=linux GOARCH=amd64 go build exec.go
```

Pull the upstream Docker image:

```
docker pull openwhisk/dockerskeleton
```

Create a custom docker image based on `openwhisk/dockerskeleton`:

```
FROM openwhisk/dockerskeleton

COPY exec /action/exec
```

Build and test:

```
$ docker build -t you/openwhisk-exec-test .
$ docker run you/openwhisk-exec-test /action/exec '{"name": "James"}'
{"msg":"Hello, James!"}
```

## OpenWhisk Hello Go/Docker 

Push up the docker image to dockerhub:

```
docker push you/openwhisk-exec-test
```

Create the OpenWhisk action:

```
wsk action create go_test --docker you/openwhisk-exec-test
```

Invoke the action to verify it works:

```
$ wsk action invoke go_test --blocking --result
{
    "msg": "Hello, Stranger!"
}
$ wsk action invoke go_test --blocking --result --param name James
{
    "msg": "Hello, James!"
}
```

## Define custom actions

### Get a list of AWS users using aws-go-sdk 

Save this to `main.go`

```
package main

import (
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/aws/aws-sdk-go/aws/session"
	"fmt"
	"encoding/json"
	"os"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
)

type Params struct {
	AwsAccessKeyId string
	AwsSecretAccessKey string
}

type Result struct {
	Doc interface{} `json:"doc"`
}

func main() {

	// native actions receive one argument, the JSON object as a string
	arg := os.Args[1]

	// unmarshal the string to a JSON object
	var params Params
	json.Unmarshal([]byte(arg), &params)

	sess, err := session.NewSession(&aws.Config{
		Credentials: credentials.NewCredentials(
			&credentials.StaticProvider{Value: credentials.Value{
				AccessKeyID:     params.AwsAccessKeyId,
				SecretAccessKey: params.AwsSecretAccessKey,
			}},
		),
	})

	// Create the service's client with the session.
	svc := iam.New(sess)

	listUsersInput := &iam.ListUsersInput{}

	listUsersOutput, err := svc.ListUsers(listUsersInput)
	if err != nil {
		panic(fmt.Sprintf("Error listing users: %v", err))
	}

	result := Result{
		Doc: listUsersOutput,
	}

	outputBytes, err := json.Marshal(result)
	if err != nil {
		panic(fmt.Sprintf("Error marshalling outputBytes: %v", err))
	}

	fmt.Printf("%s", string(outputBytes))

}
```

Build and package into docker image, and push up to docker hub

```
$ env GOOS=linux GOARCH=amd64 go build -o exec main.go
$ docker build -t you/fetch-aws-keys .
$ docker push you/fetch-aws-keys
```

Create an OpenWhisk action:

```
wsk action create fetch_aws_keys --docker you/fetch-aws-keys --param AwsAccessKeyId "YOURKEY" --param AwsSecretAccessKey "YOURSECRET"
```

Invoke it:

```
$ wsk action invoke fetch_aws_keys --blocking --result
{
    "doc": {
        "IsTruncated": false,
        "Marker": null,
        "Users": [
            {
                "Arn": "arn:aws:iam::9798798:user/some.user@yourcompany.co",
                "CreateDate": "2016-01-11T23:49:40Z",
                "PasswordLastUsed": "2017-06-07T17:41:08Z",
                "Path": "/",
                "UserId": "AIDAHGJJK87878KKW",
                "UserName": "some.user@yourcompany.co"
            },
        ...
    ]
}
```

### Write to a CloudantDB

#### Cloudant Setup

Create a Cloudant database via the Bluemix web admin.  

Under the **Permissions** control panel section for the database, choose **Generate a new API key**.

Check the **_writer** permission and make a note of the **Key** and **Password**

Verify connectivity by making a curl request:

```
$ curl -u "yourkey:yourpassword" http://67687-818ca382-081d--bluemix.cloudant.com/yourdb/_all_docs
{"total_rows":0,"offset":0,"rows":[

]}
```

#### OpenWhisk + Cloudant

```
wsk package bind /whisk.system/cloudant myCloudant -p username MYUSERNAME -p password MYPASSWORD -p host MYCLOUDANTACCOUNT.cloudant.com
```

I'm currently getting this error:

```
error: Binding creation failed: The supplied authentication is not authorized to access this resource. (code 751)
```

### Switch to BlueMix

At this point I swiched to the OpenWhisk on Bluemix, and downloaded the `wsk` cli from the Bluemix website, and configure it with my api key per the instructions.  Then I re-installed the action via:

```
wsk action create fetch_aws_keys --docker you/fetch-aws-keys --param AwsAccessKeyId "YOURKEY" --param AwsSecretAccessKey "YOURSECRET"
```

and made sure it worked by running:


```
$ wsk action invoke fetch_aws_keys --blocking --result
```

#### Cloudant Setup

Following [these instructions](https://github.com/apache/incubator-openwhisk-package-cloudant/blob/master/README.md#setting-up-a-cloudant-database-in-bluemix):

You can get your Bluemix Org name (maybe the first part of your email address by default) and BlueMix space (dev by default) from the Bluemix web admin.

```
$ wsk property set --namespace myBluemixOrg_myBluemixSpace
ok: whisk namespace set to myBluemixOrg_myBluemixSpace
```

Refresh packages:

```
$ wsk package refresh
myBluemixOrg_myBluemixSpace refreshed successfully
created bindings:
updated bindings:
deleted bindings:
```

It didn't work according to the docs, and no bindings were created even though I had created a Cloudant database in the Bluemix admin earlier.

I retried the `package bind` command that had failed earlier:

```
wsk package bind /whisk.system/cloudant myCloudant -p username MYUSERNAME -p password MYPASSWORD -p host MYCLOUDANTACCOUNT.cloudant.com
```

and this time success!!

```
ok: created binding myCloudant
```

Try writing to the db with:

```
$ wsk action invoke /yournamespace/myCloudant/write --blocking --result --param dbname yourdb --param doc "{\"_id\":\"heisenberg\",\"name\":\"Walter White\"}"
```

and you should get a response like:

```
{
    "id": "heisenberg",
    "ok": true,
    "rev": "1-f413f4b74a724e391fa5dd2e9c8e9d3f"
}
```

## Connect them in a sequence

### Create a new package binding pinned to a particular db

The `/yournamespace/myCloudant/write` action expects a `dbname` parameter, but the upstream `fetch_aws_keys` doesn't contain that parameter.  (and it's better that it doesn't, to reduce decoupling).  So if you try to connect the two actions in a sequence at this point, it will fail.

```
$ wsk package bind /whisk.system/cloudant myCloudantTestDb -p username MYUSERNAME -p password MYPASSWORD -p host MYCLOUDANTACCOUNT.cloudant.com -p dbname testdb
```

### Create sequence action

Create a sequence that will invoke these actions in sequence:

```
$ wsk action create fetch_and_write_aws_keys --sequence fetch_aws_keys,/namespace/myCloudantTestDb/write
```

1. Fetch the AWS keys 
1. Write the doc containing the AWS keys to the `testdb` database bound to the myCloudantTestDb package

Try it out:

```
$ wsk action invoke fetch_and_write_aws_keys --blocking --result
{
    "id": "d80f24dc270208191c07c802bee4e58d",
    "ok": true,
    "rev": "1-ff66b6a20f50ea36d9019481276aa0bb"
}
```

To view the resulting document:

```
wsk action invoke /traun.leyden_dev/cloudantKeynuker/read --blocking --result --param id d80f24dc270208191c07c802bee4e58d
{
    "IsTruncated": false,
    "Marker": null,
    "Users": [
        {
            "Arn": "arn:aws:iam::9798798:user/some.user@yourcompany.co",
            "CreateDate": "2016-01-11T23:49:40Z",
            "PasswordLastUsed": "2017-06-07T17:41:08Z",
            "Path": "/",
            "UserId": "AIDAHGJJK87878KKW",
            "UserName": "ome.user@yourcompany.co"
        },
```


## Drive with a scheduler 

Let's say we wanted this to run every minute.

First create an alarm trigger that will fire every minute:

```
$ wsk trigger create everyMinute --feed /whisk.system/alarms/alarm -p cron '* * * * *'
```

Now create a rule that will invoke the `fetch_and_write_aws_keys` action (which is a sequence action) whenever the `everyMinute` feed is triggered:

```
$ wsk rule create fetch_and_write_aws_keys_every_minute everyMinute fetch_and_write_aws_keys
```

To verify that it is working, check your cloudant database to look for new docs:

```
$ curl -u "yourkey:yourpassword" http://67687-818ca382-081d--bluemix.cloudant.com/yourdb/_all_docs
```

Or you can also monitor the activations:

```
$ wsk activation poll
Activation: everyMinute (f454e74ae4254657b0c920d14ea0d078)
[]

Activation: write (5d0e5c2a5af449efa1063b8dab71ba40)
[
    "2017-07-04T18:49:01.820736174Z stdout: success { ok: true,",
    "2017-07-04T18:49:01.820773215Z stdout: id: '6a3e007478278726c5ecd7c85a9fe845',",
    "2017-07-04T18:49:01.820781052Z stdout: rev: '1-25dae194be45260756aa43454fa28e60' }"
]

Activation: fetch_aws_keys (5d3a343b5a224130b4ea4bcb82517dc3)
[
    "2017-07-04T18:49:01.748729114Z stdout: XXX_THE_END_OF_A_WHISK_ACTIVATION_XXX",
    "2017-07-04T18:49:01.748801169Z stderr: XXX_THE_END_OF_A_WHISK_ACTIVATION_XXX"
]

Activation: fetch_and_write_aws_keys (14619d5125a247f983a6d1e840820bb4)
[
    "5d3a343b5a224130b4ea4bcb82517dc3",
    "5d0e5c2a5af449efa1063b8dab71ba40"
]

Activation: fetch_and_write_aws_keys_every_minute (de37f6b2bbaa407eb343b3859d9b3f74)
[]

```


