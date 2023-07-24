Class dc.webtiming.CSPSessionEvents Extends %CSP.SessionEvents
{

ClassMethod OnStartRequest() As %Status
{
    Return ##class(dc.webtiming.Events).OnStart()
}

/// Called when we have finished processing this request
ClassMethod OnEndRequest() As %Status
{
    Return ##class(dc.webtiming.Events).OnEnd()
}

}
