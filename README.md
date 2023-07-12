 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/web-timing-logger)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fweb-timing-logger&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fweb-timing-logger)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fweb-timing-logger&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fweb-timing-logger)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat&logo=AdGuard)](LICENSE)
# web-timing-logger

This is a package allowing you to record: timing, global ref, lines executed and few metrics for each incoming HTTP request.  


## Installation Docker

Clone/git pull the repo into any local directory

```
$ git clone https://github.com/lscalese/iris-web-timing-logger.git
```

Open the terminal in this directory and call the command to build and run InterSystems IRIS in container:  
*Note: Users running containers on a Linux CLI, should use "docker compose" instead of "docker-compose"*  
*See [Install the Compose plugin](https://docs.docker.com/compose/install/linux/)*

```
$ docker-compose up -d
```

## Installation ZPM

Open an IRIS terminal:

```
zpm "install web-timing-logger"
```

## Unit tests

```
zpm "test web-timing-logger"
```

## Setup

*Note: If you use docker for testing, all of actions described below are automatically performed at build time*

Firstable, initialize parameters:
```
Do ##class(dc.webtiming.Config).Initialize()
```

Enable log for incoming http request : 
```
Do ##class(dc.webtiming.Config).SetLogEnabled(1) ; or 0 to disable
```

Enable metrics for SAM : 
```
Do ##class(dc.webtiming.Config).SetMetricsEnabled(1) ; or 0 to disable
```

Configure SAM:
```
Do ##class(dc.webtiming.Utils).ConfigureAPIMonitor()
```

*optional: if you want to map this package and its data in %ALL namespace*
```
Do ##class(dc.webtiming.Utils).AddToPercentAllNS()
```

All of action above can done in one line with:   
```
Do ##class(dc.webtiming.Config).DefaultSetup()
```

## What does it do

For each incoming HTTP request it records the following informations in `dc_webtiming_log.Request` table: 

 * Date and time
 * Connected user
 * Global Reference
 * Lines executed
 * Response time in ms.
 * Http method
 * IP address of the caller
 * HTTP status code of the response
 * URL
 * Execution namespace
 * Page name if applicable (csp file)
 * Web application name

It also increment metrics that can be availalbe with SAM (/api/monitor).

### Metrics description

`webmeasure_total_hit{id="/api/monitor/"} 93`  
The number of incoming request to the web application `/api/monitor/` today

`webmeasure_total_hit_current_quarter{id="/api/monitor/"} 71`  
The number of incoming request to the web application `/api/monitor/` for the current quarter-hour.  
So 'current_quarter' metrics are reset every 15 minutes.  

`webmeasure_total_gloref{id="/api/monitor/"} 84444`  
The global reference total today for the web application `/api/monitor`.  

`webmeasure_total_gloref_current_quarter{id="/api/monitor/"} 63981`  
The total of global reference for the current quarter-hour.  

`webmeasure_total_lines{id="/api/monitor/"} 2704084` 
Total lines of code executed for all requests in `/api/monitor/`  

`webmeasure_total_lines_current_quarter{id="/api/monitor/"} 2059805`  
Total lines of code executed for the current quarter-hour.  

`webmeasure_total_timing{id="/api/monitor/"} 2261.548`  
Total time in millisecond for all requests today.  

`webmeasure_total_timing_current_quarter{id="/api/monitor/"} 1653.231`  
Total time in millisecond for the current quarter-hour.  

`webmeasure_max_lines{id="/api/monitor/"} 30966`  
The maximum lines of code executed for a request today.  

`webmeasure_max_lines_current_quarter{id="/api/monitor/"} 29076`  
The maximum lines of code executed for a request this quarter-hour.  

`webmeasure_max_timing{id="/api/monitor/"} 50.495`  
Slowness response time today for a request (time in millisecond).  

`webmeasure_max_timing_current_quarter{id="/api/monitor/"} 32.742`  
Slowness response time this current quarter-hour (time in millisecond).  

`webmeasure_average_gloref{id="/api/monitor/"} 908`  
The average global reference total today for the application `/api/monitor/`.  

`webmeasure_average_gloref_current_quarter{id="/api/monitor/"} 901.1408450704225352`  
The average global reference this current quarter-hour for the application `/api/monitor/`.  


`webmeasure_average_lines{id="/api/monitor/"} 29076.17204301075269`  
Average lines of code executed for a request tody.  

`webmeasure_average_lines_current_quarter{id="/api/monitor/"} 29011.33802816901408`  
Average lines of code executed the current quarter-hour for a request.  

`webmeasure_average_timing{id="/api/monitor/"} 24.31772043010752688`  
Average response time for a request today in millisecond.  

`webmeasure_average_timing_current_quarter{id="/api/monitor/"} 23.28494366197183099`  
Average response time for a request this current quarter-hour in millisecond.  


## How It works

It works with `%CSP.SessionEvents` class.  
So, you need to setup your web application with the event class `dc.webtiming.CSPSessionEvents` for all web applications you need.   


## Generate data

Generate fake data for testing purpose:

```
Do ##class(dc.webtiming.Utils).GenerateFakeData("/fake/webapp", 100)
```

It generates 100 http requests logs and the related metrics informations.  

Open the url http://localhost:52773/api/monitor/metrics to see the `webmeasure` metrics.  
Execute the simple following query to see the log: 
```SQL
SELECT * FROM dc_webtiming_log.Request
```


More informations will be available soon in an article on Intersystems Developer Community.