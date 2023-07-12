Class tests.dc.webtiming.TestWebTiming Extends %UnitTest.TestCase
{

Method OnBeforeAllTests() As %Status
{
	Merge ^dc.webtiming("config-backup") = ^dc.webtiming("config")
    Kill ^dc.webtiming("config")
	Quit $$$OK
}

Method OnAfterAllTests() As %Status
{
	Kill ^dc.webtiming("config")
	Merge ^dc.webtiming("config") = ^dc.webtiming("config-backup")
	Quit $$$OK
}

Method Test01Initialize()
{
    Set sc = ##class(dc.webtiming.Config).Initialize()
    
    Do $$$AssertStatusOK(sc, "Initialize default configuration.")

    Do $$$AssertEquals(##class(dc.webtiming.Config).IsLogEnabled(), "0", "Check if log is disabled by default.")
    Do $$$AssertEquals(##class(dc.webtiming.Config).IsMeasureEnabled(), "1", "Check if measure are enabled by default.")
    Do $$$AssertEquals(##class(dc.webtiming.Config).IsMetricsEnabled(), "0", "Check if metrics are disabled by default.")
    Do $$$AssertEquals(##class(dc.webtiming.Config).GetConfig("LogStopAt"), "", "Check if LogStopAt is empty by default.")

    Quit
}

Method Test02CheckParameter()
{

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetLogEnabled($$$NO), "Disable log.")
    Do $$$AssertNotTrue(##class(dc.webtiming.Config).IsLogEnabled(), "Log are disabled.")

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetMeasureEnabled($$$NO), "Disable measures.")
    Do $$$AssertNotTrue(##class(dc.webtiming.Config).IsMeasureEnabled(), "Measures are disabled.")

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetMetricsEnabled($$$NO), "Disable metrics.")
    Do $$$AssertNotTrue(##class(dc.webtiming.Config).IsMetricsEnabled(), "Metrics are disabled.")

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetLogEnabled($$$YES), "Enable log.")
    Do $$$AssertTrue(##class(dc.webtiming.Config).IsLogEnabled(), "Log are enabled.")

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetMeasureEnabled($$$YES), "Enable measures.")
    Do $$$AssertTrue(##class(dc.webtiming.Config).IsMeasureEnabled(), "Measures are enabled.")

    Do $$$AssertStatusOK(##class(dc.webtiming.Config).SetMetricsEnabled($$$YES), "Enable metrics.")
    Do $$$AssertTrue(##class(dc.webtiming.Config).IsMetricsEnabled(), "Metrics are enabled.")
}

Method Test03GenerateData()
{
    Set sc = $$$OK
    TSTART

    Try {
        Set sc = ##class(dc.webtiming.Utils).GenerateFakeData("/zzunittest/", 3)

        TROLLBACK 1
    
    } Catch ex {
    
        TROLLBACK 1
        Set sc = ex.AsStatus()
    
    }

    Do $$$AssertStatusOK(sc, "Generate fake data.")
}

}
