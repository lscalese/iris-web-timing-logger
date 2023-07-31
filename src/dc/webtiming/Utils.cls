Include dc.webtiming.macro

Class dc.webtiming.Utils
{

ClassMethod GetCleanURL(
	Application As %String = {$Select($IsObject(%request):%request.Application,1:"")},
	URL As %String = {$Select($IsObject(%request):%request.URL,1:"")}) As %String
{
    If Application = "" Return ""

    If '..IsRestApplication(Application, .DispatchClass, .sc) Return $Select($$$ISOK(sc): $Piece(URL, "?", 1), 1: "")

    Set URL = $Extract($Piece(URL, "?", 1), $Length(Application), *)

    Set route = ..BuildRoute(URL, DispatchClass, , .match)

    If match Return $Extract(Application, 1, *-1) _ route

    Set sc = $$$ERROR(5001, $$$FormatText("REST route not found in web application %2 for URL %3", Application, URL))
    
    $$$SETLASTERR(sc)

    Return ""
}

ClassMethod BuildRoute(
	OriginalURL As %String,
	DispatchClass As %String = "",
	Output out As %String = "",
	Output match As %Boolean = {$$$NO}) As %String
{
    Set tMapEntry = $ClassMethod(DispatchClass, "DispatchMap", OriginalURL, "OPTIONS", .match, .tMatcher)
	
	If tMapEntry = "" Return ""
	
	If $List(tMapEntry, 1) = "R" Set match = $$$YES Return out _ $Replace(tMatcher.Pattern, "([^/]+)", "<parameter>")
	
	Set tRegEx = $List(tMapEntry,2),
		DispatchClass = $List(tMapEntry,3),
		out = out _ $Replace(tRegEx,"(/.*)?", "")
        
	Set pTargetUrl = $Case(tRegEx, "":"", :tMatcher.Group(tMatcher.GroupCount))
	
	Return ..BuildRoute(pTargetUrl, DispatchClass, .out, .match)
}

ClassMethod IsRestApplication(
	Application As %String,
	Output DispatchClass As %String = "",
	Output sc As %Status = {$$$OK}) As %Boolean
{
    New $Roles
    
    If $Roles '[ "%All", $Roles '[ "%DB_IRISSYS" Set $Roles = $Roles _ ",%DB_IRISSYS"
    
    Set:$Extract(Application, *)="/" Application = $Extract(Application, 1, *-1)

    If $Data(^|"%SYS"|SYS("Security","ApplicationsD", Application), cfg) Set DispatchClass = $ListGet(cfg, 34) Return DispatchClass '= ""

    Set sc = $$$ERROR(5001, $$$FormatText("Web application %2 not found.", Application))

    $$$SETLASTERR(sc)
    
    Return $$$NO
}

ClassMethod GenerateFakeData(
	Application As %String = "/ztest/app",
	nb As %Integer = 100) As %Status
{
    Set sc = $$$OK
    
    Set IsMetricsEnabled = ##class(dc.webtiming.Config).IsMetricsEnabled()
    Set IsLogEnabled = ##class(dc.webtiming.Config).IsLogEnabled()

    Set methods = $ListBuild("GET","POST","PUT"), lbml = $LL(methods)
    Set pages = $ListBuild("login.csp", "main.csp", "patient.csp", "observation.csp", "agenda.csp", "patient/"_$r(10000)_"/lab"), lbpl = $LL(pages)

    Set session = {"Username" : "fakeuser"}
    Set response = {"Status" : "200"}

    Set request = ##class(%CSP.Request).%New()
    Set request.CgiEnvs("REMOTE_ADDR") = "127.0.0.1"
    ;Set request.Application = Application  ; Application is private we can't do this
    
    Set name = $Parameter("dc.webtiming.Measure","DEFAULT")

    For i=1:1:nb {

        Set request.Method = $ListGet(methods, 1 + $Random(lbml))
        Set request.PageName = $ListGet(pages, 1 + $Random(lbpl))
        Set request.URL = Application _ "/" _ request.PageName

        Set $$$MEASUREVAR(name, "lines") = $Random(1000000)
        Set $$$MEASUREVAR(name, "timing") = $Random(3000000)
        Set $$$MEASUREVAR(name, "globals") = $Random($$$MEASUREVAR(name, "lines"))
        Do ##class(dc.webtiming.Measure).SetCleanURL(request.URL)

        If IsMetricsEnabled Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Metrics).SetMetrics())
        If IsLogEnabled Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Logger).LogRequest(name, session, request, response))
    }

    Return sc
}

}
