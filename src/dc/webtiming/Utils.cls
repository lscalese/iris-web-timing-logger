Include dc.webtiming.macro

Class dc.webtiming.Utils
{

ClassMethod GenerateFakeData(
	Application As %String = "/ztest/app",
	nb As %Integer = 100) As %Status
{
    Set sc = $$$OK
    
    Set IsMetricsEnabled = ##class(dc.webtiming.Config).IsMetricsEnabled()
    Set IsLogEnabled = ##class(dc.webtiming.Config).IsLogEnabled()

    Set methods = $ListBuild("GET","POST","PUT"), lbml = $LL(methods)
    Set pages = $ListBuild("login.csp", "main.csp", "patient.csp", "observation.csp", "agenda.csp"), lbpl = $LL(pages)

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

        If IsMetricsEnabled Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Metrics).SetMetrics(Application))
        If IsLogEnabled Set sc = $$$ADDSC(sc, ##class(dc.webtiming.Logger).LogRequest(name, session, request, response))
    }

    Return sc
}

}
