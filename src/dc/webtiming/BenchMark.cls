Class dc.webtiming.BenchMark Extends %Persistent
{

Property DateTime As %TimeStamp [ InitialExpression = {$ZDateTime($Horolog, 3, 1)} ];

Property Name As %String(TRUNCATE = 1);

Property Methods As %String(MAXLEN = 2048, TRUNCATE = 1);

Property NumberOfJob As %Integer;

Property Iteration As %Integer;

Property IsLogEnabled As %Boolean [ InitialExpression = {##class(dc.webtiming.Config).IsLogEnabled()} ];

Property IsMetricsEnabled As %Boolean [ InitialExpression = {##class(dc.webtiming.Config).IsMetricsEnabled()} ];

Property Timing As %Float;

Property Lines As %Integer;

Property GloRef As %Integer;

Property AvgTiming As %Float [ Calculated, SqlComputeCode = { Set {*} = {Timing} / {Iteration} }, SqlComputed ];

Property AvgLines As %Float [ Calculated, SqlComputeCode = { Set {*} = {Lines} / {Iteration} }, SqlComputed ];

Property AvgGloref As %Float [ Calculated, SqlComputeCode = { Set {*} = {GloRef} / {Iteration} }, SqlComputed ];

Property StatusText As %String(MAXLEN = 2048, TRUNCATE = 1) [ InitialExpression = "OK" ];

Property JobNumber As %Integer [ InitialExpression = 1 ];

Property URL As %String(MAXLEN = 2048, TRUNCATE = 1);

Property WebAppType As %String;

Parameter TESTCSPAPPURL = "/csp/sys/utilhome.csp?parametername=parametervalue";

Parameter TESTRESTAPPURL = "/api/monitor/metrics?parametername=parametervalue";

/// Do ##class(dc.webtiming.BenchMark).Run()
/// Do ##class(dc.webtiming.BenchMark).Run(1)
/// Do ##class(dc.webtiming.BenchMark).Run(0,1)
ClassMethod Run(
	PurgePreviousMeasure As %Boolean = 0,
	Only1Job1Iteration As %Boolean = 0) As %Status
{
    #Dim itemTempData As %DynamicObject
    Set sc = $$$OK

    If PurgePreviousMeasure Do ..%DeleteExtent()

    Kill:$Data(^dc.webtiming("config-backup")) ^dc.webtiming("config-backup")
    Merge ^dc.webtiming("config-backup") = ^dc.webtiming("config")
    Kill:$Data(^IRIS.Temp.webtiming("perf")) ^IRIS.Temp.webtiming("perf")
    
    Set Methods = "OnStart,OnEnd"

    Try {

        Set templateName = "%1_Job(s)_Metrics_%2_Log_%3_Iteration_%4"
        
        For url = ..#TESTCSPAPPURL, ..#TESTRESTAPPURL {

            Set tempData($Increment(tempData)) = { "numberOfJob" : 1, "Iteration" : 1, "Methods" : (Methods), "URL" : (url)}
            Set:'Only1Job1Iteration tempData($Increment(tempData)) = { "numberOfJob" : 1, "Iteration" : 10000, "Methods" : (Methods), "URL" : (url)}
            Set:'Only1Job1Iteration tempData($Increment(tempData)) = { "numberOfJob" : 8, "Iteration" : 10000, "Methods" : (Methods), "URL" : (url)}
        }
        
        Set key = ""

        For  {
            Set key = $Order(tempData(key), 1, itemTempData)
            Quit:key=""
            
            Do ##class(dc.webtiming.Config).SetMeasureEnabled($$$YES)
            Do ##class(dc.webtiming.Config).SetMetricsEnabled($$$YES)
            Do ##class(dc.webtiming.Config).SetLogEnabled($$$NO)

            Set itemTempData.Name = $$$FormatText(templateName, itemTempData.numberOfJob, "Enabled", $s(##class(dc.webtiming.Config).IsLogEnabled():"Enabled",1:"Disabled"), itemTempData.Iteration)
            Set ^IRIS.Temp.webtiming("perf",itemTempData.Name) = itemTempData.%ToJSON()
            $$$TOE(sc, ..StartByWorkMgr(itemTempData.Name, itemTempData.numberOfJob))

            Do ##class(dc.webtiming.Config).SetLogEnabled($$$YES)
            Set itemTempData.Name = $$$FormatText(templateName, itemTempData.numberOfJob, "Enabled", $s(##class(dc.webtiming.Config).IsLogEnabled():"Enabled",1:"Disabled"), itemTempData.Iteration)
            Set ^IRIS.Temp.webtiming("perf",itemTempData.Name) = itemTempData.%ToJSON()
            $$$TOE(sc, ..StartByWorkMgr(itemTempData.Name, itemTempData.numberOfJob))
            
            Kill ^IRIS.Temp.webtiming("perf", itemTempData.Name)
        }
        

    } Catch ex {
        
        Set sc = ex.AsStatus()
    }
    
    
    Merge ^dc.webtiming("config") = ^dc.webtiming("config-backup")

    Kill ^IRIS.Temp.webtiming("perf"), ^dc.webtiming("config-backup")

    Quit sc
}

ClassMethod StartByWorkMgr(
	Name As %String,
	NumberOfJob As %Integer) As %Status [ Private ]
{
    If NumberOfJob = 1 Quit ..JobPerf(Name) ; we don't use the workmgr for only 1 job

    Set queue=##class(%SYSTEM.WorkMgr).%New(, 8) 
    For i=1:1:NumberOfJob Do queue.Queue("..JobPerf", Name, i)
    Quit queue.WaitForComplete()
}

ClassMethod JobPerf(
	Name As %String,
	JobNumber As %Integer = 1) As %Status
{
    $$$QuitOnError(..CommonStartJobPerf(Name, .MeasureData, .record))
    
    For i=1:1:MeasureData.Iteration Do ##class(dc.webtiming.Events).OnStart(), ##class(dc.webtiming.Events).OnEnd()

    Set:JobNumber>1 record.JobNumber = JobNumber

    Quit ..CommonEndJobPerf(.MeasureData, .record)
}

ClassMethod CommonStartJobPerf(
	Name As %String,
	Output MeasureData As %DynamicObject,
	Output record As dc.webtiming.BenchMark) As %Status
{
    Set MeasureData = {}.%FromJSON(^IRIS.Temp.webtiming("perf", Name))
    
    Set sc = ..InitializeJob(.MeasureData, .record)
    If $$$ISERR(sc) Set record.StatusText = $SYSTEM.Status.GetErrorText(sc) Do record.%Save() Quit sc

    Set MeasureData.Time = $ZHorolog,
        MeasureData.Lines =  $SYSTEM.Process.LinesExecuted($Job),
        MeasureData.Gloref = $$$GlobalRefs
    
    Quit sc
}

ClassMethod CommonEndJobPerf(
	MeasureData As %DynamicObject,
	record As dc.webtiming.BenchMark) As %Status
{
    Set MeasureData.Time = $ZHorolog - MeasureData.Time, 
        MeasureData.Lines = $SYSTEM.Process.LinesExecuted($Job) - MeasureData.Lines, 
        MeasureData.Gloref = $$$GlobalRefs - MeasureData.Gloref
        
    Set record.Timing = MeasureData.Time, record.Lines = MeasureData.Lines, record.GloRef = MeasureData.Gloref, record.Methods = MeasureData.Methods
    
    Quit record.%Save()
}

ClassMethod InitializeJob(
	MeasureData As %DynamicObject,
	ByRef record As dc.webtiming.BenchMark) As %Status
{
    Set sc = $$$OK
    
    Set %request = ##class(%CSP.Request).%New()
   
    Set %request.CgiEnvs("REMOTE_ADDR") = "127.0.0.1"
    Set %request.Method = "GET"
    
    Set currentNs = $Namespace, sc = %request.UpdateURL(MeasureData.URL), $Namespace = currentNs
    
    ; set a fake %session object, we need only the Username property
    Set %session = {"Username" : "fakeuser"}
    ; set a fake %session object, we need only the Status property
    Set %response = {"Status" : "200"}

    Set record = ..%New(), 
        record.Name = MeasureData.Name, 
        record.NumberOfJob = MeasureData.numberOfJob, 
        record.Iteration = MeasureData.Iteration,
        record.URL = MeasureData.URL,
        record.WebAppType = $Select(##class(dc.webtiming.Utils).IsRestApplication(%request.Application): "REST", 1: "CSP")

    If $$$ISERR(sc) Set record.StatusText = $SYSTEM.Status.GetErrorText(sc) Do record.%Save()

    Quit sc
}

Method %OnAfterSave(insert As %Boolean) As %Status
{
    If 'insert Quit $$$OK

    Set sc = $$$OK

    Set (metricsIdTemplate, metricsId) = "{{WebAppType}}_{{NumberOfJob}}_Job(s)_Log_{{IsLogEnabled}}_Iteration_{{Iteration}}_jobnumer_{{JobNumber}}"
    
    Set matcher=##class(%Regex.Matcher).%New("\{\{(.*?)\}\}")      

    Set matcher.Text = metricsIdTemplate
    
    While matcher.Locate() {
        Set metricsId = $Replace(metricsId, matcher.Group, $Property(##this, $Extract(matcher.Group,3,*-2)) )
    }

    Set ^dc.webtiming.Metrics.bm(metricsId) = $ListBuild(..GloRef, ..Lines, ..Timing)

    Quit sc
}

ClassMethod CompareDispatchClassMethod(n As %Integer = 1000)
{
    Write !, $ZDateTime($Horolog, 3, 1), " * Compare IsRestApplication against GetDispatchClass."

    Write !, $ZDateTime($Horolog, 3, 1), "   Run IsRestApplication ", n, " times."

    Set start = $zh

    For i=1:1:n Do ##class(dc.webtiming.Utils).IsRestApplication("/api/monitor/", .dispatch, .sc)

    Set time1 = $zh - start

    Write !, $ZDateTime($Horolog, 3, 1), "     Total time (sec)   : ", time1
    Write !, $ZDateTime($Horolog, 3, 1), "     Average time (sec) : ", (time1 / n)

    Write !, $ZDateTime($Horolog, 3, 1), "   Run GetDispatchClass ", n, " times."

    Set start = $zh

    For i=1:1:n Set dispatch = ..GetDispatchClass("/api/monitor/", .sc)

    Set time2 = $zh - start

    Write !, $ZDateTime($Horolog, 3, 1), "     Total time (sec)   : ", time2
    Write !, $ZDateTime($Horolog, 3, 1), "     Average time (sec) : ", (time2 / n)

    Set msg = "%1 is %2 times faster than %3"

    If time1 > time2 {
        Set xTimes = time1 / time2, msg = $$$FormatText(msg, "IsRestApplication", xTimes, "GetDispatchClass")
    } Else {
        Set xTimes = time2 / time1, msg = $$$FormatText(msg, "GetDispatchClass", xTimes, "IsRestApplication")
    }

    Write !, $ZDateTime($Horolog, 3, 1), " = ", msg
    Write !, $ZDateTime($Horolog, 3, 1), " ------------------------------------------------------"

    Quit
}

ClassMethod GetDispatchClass(
	Application As %String,
	ByRef sc As %Status = {$$$OK}) As %String
{
    Set currentRoles = $Roles

    New $Roles, $Namespace
    Set $Roles = "%ALL", $Namespace = "%SYS", DispatchClass = ""
    
    Try {
        Do ##class(Security.Applications).Get(Application, .properties)
        Set DispatchClass = properties("DispatchClass")
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    
    Set $Roles = currentRoles

    Return DispatchClass
}

Storage Default
{
<Data name="BenchMarkDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DateTime</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Methods</Value>
</Value>
<Value name="5">
<Value>NumberOfJob</Value>
</Value>
<Value name="6">
<Value>IsLogEnabled</Value>
</Value>
<Value name="7">
<Value>IsMetricsEnabled</Value>
</Value>
<Value name="9">
<Value>Timing</Value>
</Value>
<Value name="10">
<Value>Lines</Value>
</Value>
<Value name="11">
<Value>GloRef</Value>
</Value>
<Value name="12">
<Value>Iteration</Value>
</Value>
<Value name="13">
<Value>StatusText</Value>
</Value>
<Value name="14">
<Value>JobNumber</Value>
</Value>
<Value name="15">
<Value>URL</Value>
</Value>
<Value name="16">
<Value>WebAppType</Value>
</Value>
</Data>
<DataLocation>^dc.webtiming.BenchMarkD</DataLocation>
<DefaultData>BenchMarkDefaultData</DefaultData>
<IdLocation>^dc.webtiming.BenchMarkD</IdLocation>
<IndexLocation>^dc.webtiming.BenchMarkI</IndexLocation>
<StreamLocation>^dc.webtiming.BenchMarkS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
