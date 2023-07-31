Class dc.webtiming.Config
{

ClassMethod IsLogEnabled() As %Boolean
{
    Set stopAt = ..GetConfig("LogStopAt")

    If stopAt = "" Return ''..GetConfig("LogEnabled")

    If $ZDateTime($Horolog, 3, 1) ]] stopAt Do ..SetLogEnabled($$$NO), ..SetConfig("LogStopAt", "") Return $$$NO

    Return ''..GetConfig("LogEnabled")
}

ClassMethod IsMeasureEnabled() As %Boolean
{
    Return ''..GetConfig("MeasureEnabled")
}

ClassMethod IsMetricsEnabled() As %Boolean
{
    Return ''..GetConfig("MetricsEnabled")
}

ClassMethod SetLogEnabled(value As %Boolean) As %Boolean
{
    Return ..SetConfig("LogEnabled", value)
}

ClassMethod SetMeasureEnabled(value As %Boolean) As %Boolean
{
    Return ..SetConfig("MeasureEnabled", value)
}

ClassMethod SetMetricsEnabled(value As %Boolean) As %Boolean
{
    Return ..SetConfig("MetricsEnabled", value)
}

ClassMethod GetConfig(key As %String) As %String
{
    If $Get(key) = "" Return ""

    Return $Get(^dc.webtiming("config", key))
}

ClassMethod EnableLogForXXMinutes(minutes As %Integer = 1) As %Status
{
    Set stopAt = $SYSTEM.SQL.Functions.DATEADD( "mi", minutes, $ZDateTime($Horolog, 3, 1))

    Do ..SetLogEnabled($$$YES), ..SetConfig("LogStopAt", stopAt)
    
    Job ##class(dc.webtiming.Config).AutoStopInXXMinutes(minutes)

    Return $$$OK
}

ClassMethod AutoStopInXXMinutes(minutes) As %Status
{
    Hang minutes * 60

    Do ..SetConfig("LogStopAt", "")

    Return ..SetLogEnabled($$$NO)
}

ClassMethod SetConfig(
	key As %String,
	value As %String) As %Status
{
    If '..IsValidKey(.key) Return $$$ERROR(5001, key _ " is not a valid configuration key.")

    Set ^dc.webtiming("config", key) = value
    Return $$$OK
}

ClassMethod IsValidKey(key As %String) As %Boolean [ CodeMode = expression ]
{
''$ListFind(..GetListConfigKey(), key)
}

ClassMethod GetListConfigKey() As %List [ CodeMode = objectgenerator ]
{
    
    #dim json As %DynamicObject = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId("dc.webtiming.Config||Description").Data)

    #dim iter As %Iterator.Object = json.%GetIterator()

    Set list = ""

    While iter.%GetNext(.key, .value, .type) {
        Set $List(list, $ll(list)+1) = key
    }

    Do %code.WriteLine($Char(9) _ "Return $ListFromString(""" _ $ListToString(list) _ """)")
    
    Return $$$OK
}

ClassMethod AddUrlRegExp(
	regexp As %String,
	replaceString As %String) As %Status
{

    Return $$$OK
}

ClassMethod Initialize() As %Status [ CodeMode = objectgenerator ]
{
    #dim json As %DynamicObject = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId("dc.webtiming.Config||Description").Data)

    #dim iter As %Iterator.Object = json.%GetIterator()

    While iter.%GetNext(.key, .value, .type) {
        Do %code.WriteLine( $Char(9) _ $$$FormatText("Do:'$Data(^dc.webtiming(""config"", ""%1"")) ..SetConfig(""%1"", ""%2"")", key, value.Default))
    }

    Do %code.WriteLine( $Char(9) _ "Return $$$OK")

    Return $$$OK
}

ClassMethod Reset() As %Status [ CodeMode = objectgenerator ]
{
    #dim json As %DynamicObject = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId("dc.webtiming.Config||Description").Data)

    #dim iter As %Iterator.Object = json.%GetIterator()

    Do %code.WriteLine( $Char(9) _ "Kill ^dc.webtiming(""config"")")

    While iter.%GetNext(.key, .value, .type) {
        Do %code.WriteLine( $Char(9) _ $$$FormatText("Do ..SetConfig(""%1"", ""%2"")", key, value.Default))
    }

    Do %code.WriteLine( $Char(9) _ "Return $$$OK")

    Return $$$OK
}

ClassMethod ConfigureAPIMonitor() As %Status
{
    Set sc = $$$OK, oldNs = $Namespace
    
    New $Namespace
    Set $Namespace = "%SYS"

    Do ##class(Security.Applications).Get("/api/monitor",.p)

    Do ##class(Config.Namespaces).Get(oldNs, .pn)

    Set updateCsp = $$$NO
    
    For dbName = pn("Globals"), pn("Routines") {
        Do ##Class(Config.Databases).Get(dbName, .pdb)

        Set db = ##class(SYS.Database).%OpenId(pdb("Directory"))
        If '$ISOBJECT(db) Kill pdb Continue

        If p("MatchRoles") [ db.ResourceName Kill pdb Continue
        
        Set p("MatchRoles") = p("MatchRoles") _ ":" _ db.ResourceName

        Set updateCsp = $$$YES
        Kill pdb
    }
    
    Set:updateCsp sc = $$$ADDSC(sc, ##class(Security.Applications).Modify("/api/monitor",.p))

    Set sc = $$$ADDSC(sc, ##class(SYS.Monitor.SAM.Config).AddApplicationClass("dc.webtiming.Metrics", oldNs))

    Return sc
}

ClassMethod AddToPercentAllNS() As %Status
{
    Set sc = $$$OK, oldNs = $Namespace
    
    New $Namespace
    Set $Namespace = "%SYS"

    If '##class(Config.Namespaces).Exists("%ALL") {
        Set nsCfg("Globals")="%DEFAULTDB"
        Set sc=$$$ADDSC(sc, ##Class(Config.Namespaces).Create("%ALL",.nsCfg))
    }

    Do ##class(Config.Namespaces).Get(oldNs, .cNs)

    If '##class(Config.MapPackages).Exists("%ALL","dc.webtiming") {
        Set mapPkg("Database") = cNs("Routines")
        Set sc = $$$ADDSC(sc, ##Class(Config.MapPackages).Create("%ALL", "dc.webtiming", .mapPkg))
    }

    If '##class(Config.MapGlobals).Exists("%ALL","dc.webtiming*") {
        Set mapGbl("Database") = cNs("Globals")
        Set sc = $$$ADDSC(sc, ##Class(Config.MapGlobals).Create("%ALL", "dc.webtiming*", .mapGbl))
    }

    Quit sc
}

ClassMethod DefaultSetup() As %Status
{
    Set sc = $$$OK

    Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Config).ConfigureAPIMonitor())
    Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Config).Initialize())
    Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Config).SetLogEnabled($$$YES))
    Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Config).SetMetricsEnabled($$$YES))
    Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Config).AddToPercentAllNS())

    Quit sc
}

ClassMethod DockerInit()
{
    Do ..DefaultSetup()

    Do ..AddEventClassToWebApp("/api/monitor", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/api/atelier", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/csp/sys", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/csp/sys/exp", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/csp/sys/mgr", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/csp/sys/op", "dc.webtiming.CSPSessionEvents")
    Do ..AddEventClassToWebApp("/csp/sys/sec", "dc.webtiming.CSPSessionEvents")

    Quit
}

ClassMethod AddEventClassToWebApp(
	Application As %String,
	EventClass As %String = "dc.webtiming.CSPSessionEvents") As %Status
{
    Set sc = $$$OK

    New $Namespace Set $Namespace = "%SYS"
    
    If '##class(Security.Applications).Exists(Application) Quit $$$ERROR(5001, $$$FormatText("Application %1 does not exist.", Application))

    Do ##class(Security.Applications).Get(Application, .p)
    Set p("EventClass") = EventClass
    Quit ##class(Security.Applications).Modify(Application, .p)
}

XData Description [ MimeType = application/json ]
{
{
        "LogEnabled" : {
            "Default" : "0",
            "Description" : "Enable/Disable log request (value 0 or 1)"
        },
        "MeasureEnabled" : {
            "Default" : "1",
            "Description": "Enable/Disable the measure of timing, global ref and executed lines (value 0 or 1)"
        },
        "MetricsEnabled" : {
            "Default" : "0",
            "Description": "Enable/Disable metrics (value 0 or 1)"
        },
        "LogStopAt" : {
            "Default" : "",
            "Description": "If the log is enabled for a short time, LogStopAt must contains the stop date time (format yyyy-mm-dd hh:mm:ss)"
        }
    }
}

}
