---
layout: post
title: "Setting up Uniqush with APNS"
date: 2016-02-03 08:47
comments: true
categories: ios docker
---

This walks you through running [Uniqush](http://uniqush.org/index.html) in the cloud (under Docker) and setting up an iOS app to receive messages via APNS (Apple Push Notification Service).

## Run Uniqush under Docker

### Config

* `mkdir -p volumes/uniqush`
* `wget https://git.io/vgYXN -O volumes/uniqush/uniqush-push.conf`

Security note: the above config has Uniqush listening on all interfaces, but depending on your setup you probably want to change that to `localhost` or something more restrictive.  

### Docker run

```
docker run -itd -p 9898:9898 -v ~/volumes/uniqush/uniqush-push.conf:/etc/uniqush/uniqush-push.conf tleyden5iwx/uniqush uniqush-push
```

### Kick off redis (hack)

So the *right* way to do this is to run redis in a separate container and link the containers via Docker Networks.  In the meantime, this little hack will work... shell into the container and kick off redis.

* `container=$(docker ps | grep -i uniqush | awk '{print $1}')`
* `docker exec -ti $container bash`
* `/etc/init.d/redis-server start`  (<--- inside the running container)
* `exit` (to get out of the container)

### Verify Uniqush is running

Run this `curl` command outside of the docker container to verify that Uniqush is responding to HTTP requests:

```
$ curl localhost:9898/version
uniqush-push 1.5.2
```


## Create APNS certificate

In my case, I already had an app id for my app (`com.couchbase.todolite`), but push notifications are not enabled, so I needed to enable them:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/todolite_app_settings.png)

Create a new push cert:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/create_new_push_cert.png)

Choose the correct app id:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/choose_app_id.png)

Generate CSR according to instructions in keychain:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/create_csr.png)

This will save a CSR on your file system, and the next wizard step will ask you to upload this CSSR and generate the certificate.  Now you can download it:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/download_cert.png)

Double click the downloaded cert and it will be added to your keychain.

This is where I got a bit confused, since I had to *also* download the cert from the app id section -- go to the app id and hit "Edit", then download the cert and double click it to add to your keychain.  (I'm confused because I thought these were the same certs and this second step felt redundant)

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/download_app_id_cert.png)


## Create and use provisioning profile

Go to the **Provisioning Profiles / Development** section and hit the "+" button:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/create_provisioning_profile.png)

Choose all certs and all devices, and then give your provisioning profile an easy to remember name.  

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/create_provisioning_profile_2.png)

Download this provisioning profile and double click it to install it.

In xcode under **Build Settings**, choose this provisioning profile:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/xcode_choose_provisioning_profile.png)

## Register for push notifications in your app

Add the following code to your `didFinishLaunchingWithOptions:`:

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Register for push notifications
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }

    // rest of your code goes here ...

}
```

And the following callback methods which will be called if remote notification is successful:

```
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
    NSString *deviceTokenStr = [NSString stringWithFormat:@"%@",deviceToken];
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken, Device token: %@", deviceTokenStr);
    
    NSString* deviceTokenCleaned = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    
     NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken, Cleaned device token token: %@", deviceTokenCleaned);

}
```

and this callback which will be called if it's not unsuccessful:

```
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    NSLog(@"Error registering device token.  Push notifications will not work%@", str);
}

```

If you now run this app on a simulator, you can expect an error like `Error registering device token.  Push notifications will not workError`.

Run the app on a device you should see a popup dialog in the app asking if it's OK to receive push notifications, and the following log messages in the xcode console:

```
didRegisterForRemoteNotificationsWithDeviceToken, Device token: <281c8710 1b029fdb 16c8e134 39436336 116001ce bf6519e6 8edefab5 23dab4e9>
didRegisterForRemoteNotificationsWithDeviceToken, Cleaned device token token: 281c87101b029fdb16c8e13439436336116001cebf6519e68edefab523dab4e9
```

## Export APNS keys to .PEM format

Open keychain, select the `login` keychain and the `My Certificates` category:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/export_cert_keychain.png)

* Right click on the certificate (not the private key) “Apple Development Push Services: (your app id)”
* Choose Export “Apple Development Push Services: (your app id)″.
* Save this as `apns-prod-cert.p12` file somewhere you can access it.
* When it prompts you for a password, leave it blank (or add one if you want, but this tutorial will assume it was left blank)
* Repeat with the private key (in this case, TodoLite Push Notification Cert) and save it as `apns-prod-key.p12`.

Now they need to be converted from `.p12` to `.pem` format.

```
$ openssl pkcs12 -clcerts -nokeys -out apns-prod-cert.pem -in apns-prod-cert.p12
Enter Import Password: <return>
MAC verified OK
```

```
$ openssl pkcs12 -nocerts -out apns-prod-key.pem -in apns-prod-key.p12
Enter Import Password:
MAC verified OK
Enter PEM pass phrase: hello <return>
```

Remove the PEM passphrase:

```
$ openssl rsa -in apns-prod-key.pem -out apns-prod-key-noenc.pem
Enter pass phrase for apns-prod-key.pem: hello
writing RSA key
```

## Add PEM files to Uniqush docker container

When you call the Uniqush REST API to add a Push Service Provider, it expects to find the PEM files on it's local file system.  Use the following commands to get these files into the running container in the `/tmp` directory:

```
$ `container=$(docker ps | grep -i uniqush | awk '{print $1}')`
$ docker cp /tmp/apns-prod-cert.pem $container:/tmp/apns-prod-cert.pem
$ docker cp /tmp/apns-prod-key-noenc.pem $container:/tmp/apns-prod-key-noenc.pem
```


## Create APNS provider in Uniqush via REST API

```
$ export UNIQUSH_HOSTNAME=ec2-54-73-10-60.compute-1.amazonaws.com:9898
$ curl -v http://$UNIQUSH_HOSTNAME/addpsp -d service=myservice \
                                          -d pushservicetype=apns \
					  -d cert=/tmp/apns-prod-cert.pem \
					  -d key=/tmp/apns-prod-key-noenc.pem \
					  -d sandbox=true
```

(Note: I'm using a development cert, but if this was a distribution cert you'd want to use `sandbox=false`)

You should get a `200 OK` response with:

```
[AddPushServiceProvider][Info] 2016/02/03 20:35:29 From=24.23.246.59:59447 Service=myservice PushServiceProvider=apns:9f49c9c618c97bebe21bea159d3c7a8577934bdf00 Success!
```


## Add Uniqush subscriber

Using the cleaned up device token from the previous step `281c87101b029fdb16c8e13439436336116001cebf6519e68edefab523dab1e9`, create a subscriber with the name `mytestsubscriber` via:

```
$ curl -v http://$UNIQUSH_HOSTNAME/subscribe -d service=myservice \
                                             -d subscriber=mytestsubscriber \
					     -d pushservicetype=apns \
					     -d devtoken=281c87101b029fdb16c8e13439436336116001cebf6519e68edefab523dab1e9 
```

You should receive a `200 OK` response with:

```
[Subscribe][Info] 2016/02/03 20:43:21 From=24.23.246.59:60299 Service=myservice Subscriber=mytestsubscriber PushServiceProvider=apns:9f49c9c618c97bebe21bea159d3c7a8577934bdf00 DeliveryPoint=apns:2cbecd0798cc6731d96d5b0fb01d813c7c9a83af00 Success!
```

## Push a test message

The moment of truth!

First, you need to either **background your app** by pressing the home button, or add [some code like this](https://gist.github.com/tleyden/97434117ad53757106ad) so that an alert will be shown if the app is foregrounded.

```
$ curl -v http://$UNIQUSH_HOSTNAME/push -d service=myservice \
                                        -d subscriber=mytestsubscriber \
					-d msg=HelloWorld
```

You should get a `200 OK` response with:

```
[Push][Info] 2016/02/03 20:46:08 RequestId=56b26710-INbW8UWMUONtH8Ttddd2Qg== From=24.23.246.59:60634 Service=myservice NrSubscribers=1 Subscribers="[mytestsubscriber]"
[Push][Info] 2016/02/03 20:46:09 RequestID=56b26710-INbW8UWMUONtH8Ttddd2Qg== Service=myservice Subscriber=mytestsubscriber PushServiceProvider=apns:9f49c9c618c97bebe21bea159d3c7a8577934bdf00 DeliveryPoint=apns:2cbecd0798cc6731d96d5b0fb01d813c7c9a83af MsgId=apns:apns:9f49c9c618c97bebe21bea159d3c7a8577934bdf-1 Success!
```

And a push notification on the device!

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/push_notification_device.png)


## References

* [Uniqush docs](http://uniqush.org/documentation/usage.html)
* [How to create APNS certificates](http://quickblox.com/developers/How_to_create_APNS_certificates)
* [How to renew your Apple Push Notification Push SSL Certificate](https://blog.serverdensity.com/how-to-renew-your-apple-push-notification-push-ssl-certificate/)