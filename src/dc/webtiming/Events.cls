Include dc.webtiming.macro

Class dc.webtiming.Events
{

ClassMethod OnStart() As %Status
{
    Try { ; just security to avoid response problem due to a bug with the monitoring ...
        
        If '##class(dc.webtiming.Config).IsMeasureEnabled() Return $$$OK

        Set sc = $$$OK,
            sc = $$$ADDSC(sc, ##class(dc.webtiming.Measure).Start()),
            sc = $$$ADDSC(sc, ##class(dc.webtiming.Measure).SetCleanURL(##class(dc.webtiming.Utils).GetCleanURL())),
            sc = $$$ADDSC(sc, ##class(dc.webtiming.Measure).SetMethod())
        
    } Catch ex { Set sc = ex.AsStatus() }

    If $$$ISOK(sc) Return sc

    $$$SETLASTERR(sc)

	Return sc
}

ClassMethod OnEnd() As %Status
{
    Try { ; just security to avoid response problem due to a bug with the monitoring ...
    
        If '##class(dc.webtiming.Config).IsMeasureEnabled() Return $$$OK

        Set sc = ##class(dc.webtiming.Measure).Stop()
        
        If ##class(dc.webtiming.Config).IsLogEnabled() Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Logger).LogRequest())
        If ##class(dc.webtiming.Config).IsMetricsEnabled() Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Metrics).SetMetrics())
    
    } Catch ex { Set sc = ex.AsStatus() }

    If $$$ISOK(sc) Return sc

    $$$SETLASTERR(sc)

    Return sc
}

}
