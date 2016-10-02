---
layout: post
title: "Configuring InfluxDB and Grafana with Go client library"
date: 2016-09-12 15:14
comments: true
categories: influxdb grafana golang
---

Create a beautiful Grafana dashboard with realtime performance stats:

![screen shot 2016-09-13 at 3 33 20 pm](https://cloud.githubusercontent.com/assets/296876/18493836/730085b0-79c7-11e6-9236-50dd3d4c72d4.png)


## Install InfluxDB and Grafana

```
brew install influxdb grafana telegraf
brew services start influxdb
brew services start grafana
brew services start telegraf
```

Versions at the time of this writing:

* InfluxDB: 1.0
* Grafana: 3.1.1

## Verify

* The Grafana Web UI should be available at [localhost:3000](http://localhost:3000/) -- login with admin/admin
* The InfluxDB Web UI should be available at [localhost:8083](http://localhost:8083/)

## Create database on influx

Create db named "db"

```
$ influx
> create database db
```

## Edit telegraf conf

Open `/usr/local/etc/telegraf.conf` in your favorite text editor and uncomment the entire statsd server section:

```
# Statsd Server
[[inputs.statsd]]
  ## Address and port to host UDP listener on
  service_address = ":8125"

  .. etc .. 
```

Set the database to use the "db" database created earlier, under the `outputs.influxdb` section of the telegraf config

```
[[outputs.influxdb]]
  ## The full HTTP or UDP endpoint URL for your InfluxDB instance.
  ## Multiple urls can be specified as part of the same cluster,
  ## this means that only ONE of the urls will be written to each interval.
  # urls = ["udp://localhost:8089"] # UDP endpoint example
  urls = ["http://localhost:8086"] # required
  ## The target database for metrics (telegraf will create it if not exists).
  database = "db" # required
```

## Restart telegraf

```
brew services restart telegraf
```

## Create Grafana Data Source

* Open the [Grafana Web UI](http://localhost:3000/) in your browsers (login with admin/admin)
* Use the following values:

![screen shot 2016-09-13 at 3 39 43 pm](https://cloud.githubusercontent.com/assets/296876/18494027/a87adcf8-79c8-11e6-912b-a5e5a82dad14.png)


## Create Grafana Dashboard

* Go to Dashboards / + New
* Click the green thing on the left, and choose Add Panel / Graph

![screen shot 2016-09-13 at 3 43 50 pm](https://cloud.githubusercontent.com/assets/296876/18494074/f230784e-79c8-11e6-9ab0-bc284b9e01f5.png)

* Delete the test metric, which is not needed, by clicking the trash can to the right of "Test Metric"

![screen shot 2016-09-13 at 3 45 04 pm](https://cloud.githubusercontent.com/assets/296876/18494109/1a927152-79c9-11e6-98f9-f338549ee3d9.png)

* Under Panel / Datasource, choose **db**, and then hit **+ Add Query**, you will end up with this

![screen shot 2016-09-13 at 3 47 21 pm](https://cloud.githubusercontent.com/assets/296876/18494180/7b8f9570-79c9-11e6-93c0-3f721d93002a.png)


## Push sample data point from command line

In order for the field we want to show up on the grafana dashboard, we need to push some data points to the telegraf statds daemon.

Run this in a shell to push the `foo:1|c` data point, which is a counter with value increasing by 1 on the key named "foo".

```
while true; do echo "foo:1|c" | nc -u -w0 127.0.0.1 8125; sleep 1; echo "pushed data point"; done
```

## Create Grafana Dashboard, Part 2

* Under **select measurement**, choose **foo** from the pulldown
* On the top right of the screen near the clock icon, choose "Last 5 minutes" and set **Refreshing every** to 5 seconds
* You should see your data point counter being increased!

![screen shot 2016-09-13 at 3 51 16 pm](https://cloud.githubusercontent.com/assets/296876/18494256/f45fe55e-79c9-11e6-9663-abf9db7e7299.png)


## Add Go client library and push data points

Here's how to update to your `golang` application to push new datapoints.

* Install the [g2s](github.com/peterbourgon/g2s) client library via:

```
$ go get github.com/peterbourgon/g2s
```

* Here is some sample code to push data points to the `statds` telegraf process from your go program:

```
statdsClient, err := g2s.Dial("udp", "http://localhost:8125")
if err != nil {
	panic("Couldn't connect to statsd!")
}
req, err := http.NewRequest("GET", "http://waynechain.com/")
resp, err := http.DefaultClient.Do(req)
if err != nil {
	return err
}
s.StatsdClient.Timing(1.0, "open_website", time.Since(startTime))
```

This will push statsd "timing" data points under the key "open_website", with the normal sample rate (set to 0.1 to downsample and only take every 10th sample).  Run the code in a loop and it will start pushing stats to `statsd`.

Now, create a new Grafana dashboard with the steps above, but from the **select measurement** field choose **open_website**, and under **SELECT** choose **field (mean)** instead of **field (value)**.  
