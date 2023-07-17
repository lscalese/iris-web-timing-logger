Class dc.webtiming.CSPSessionEvents Extends %CSP.SessionEvents
{

ClassMethod OnStartRequest() As %Status
{
    If ##class(dc.webtiming.Config).IsMeasureEnabled() {
        Do ##class(dc.webtiming.Measure).Start()
        Do ##class(dc.webtiming.Measure).SetCleanURL(##class(dc.webtiming.Utils).GetCleanURL())
    }
	
    Return $$$OK
}

/// Called when we have finished processing this request
ClassMethod OnEndRequest() As %Status
{
    If '##class(dc.webtiming.Config).IsMeasureEnabled() Return $$$OK
    
    Do ##class(dc.webtiming.Measure).Stop()
    
    If ##class(dc.webtiming.Config).IsLogEnabled() Do ##class(dc.webtiming.Logger).LogRequest()
    If ##class(dc.webtiming.Config).IsMetricsEnabled() Do ##class(dc.webtiming.Metrics).SetMetrics()
	
    Return $$$OK
}

}
