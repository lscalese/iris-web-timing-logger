Class dc.webtiming.Logger
{

ClassMethod LogRequest(
	TimerName As %String = { $Parameter("dc.webtiming.Measure","DEFAULT")},
	Session As %CSP.Session = {$Get(%session)},
	Request As %CSP.Request = {$Get(%request)},
	Response As %CSP.Response = {$Get(%response )}) As %Status
{
    If '$IsObject(Session) || '$IsObject(Request) || '$IsObject(Response) Return $$$ERROR(5001, "The arguments session, request and response are mandatory")

    Set sc = $$$OK

    Set log = ##class(dc.webtiming.log.Request).%New()

    Set log.Login = Session.Username
    
    Set log.Timer = TimerName
    Set log.Gloref = ##class(dc.webtiming.Measure).GetGlobals(TimerName)
    Set log.TimingInMs = ##class(dc.webtiming.Measure).GetTiming(TimerName)
    Set log.Lines = ##class(dc.webtiming.Measure).GetLines(TimerName)

    Set log.Method = log.MethodDisplayToLogical($Zcvt(Request.Method, "U"))
    Set log.IP = $Select($Get(Request.CgiEnvs("HTTP_X_FORWARDED_FOR"))'="": Request.CgiEnvs("HTTP_X_FORWARDED_FOR"), 1: Request.CgiEnvs("REMOTE_ADDR"))
    Set log.HttpStatusCode = $Piece(Response.Status, " ", 1)
    Set log.URL = Request.URL
    Set log.URLClean = ##class(dc.webtiming.Measure).GetCleanURL()
    Set log.PageName = Request.PageName
    Set log.Application = Request.Application
    
    ;Set oldTM = $SYSTEM.OBJ.SetTransactionMode(0), jrnState = $$CURRENT^%NOJRN
    Try {
        ;Do:jrnState DISABLE^%NOJRN
        Set sc = log.%Save()
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    ;Do $SYSTEM.OBJ.SetTransactionMode(oldTM)
    ;Do:jrnState ENABLE^%NOJRN
    
    
    Return sc
}

ClassMethod CleanData(
	RetentionInDay As %Integer = 30,
	Limit As %Integer = 10000000) As %Status
{
    Set sc = $$$OK

    Set tm = $SYSTEM.OBJ.SetTransactionMode(0)  ; Désactive les transactions pour les modifications par accès objet
    Set ac = $SYSTEM.SQL.Util.SetAutoCommit(0)  ; Désactive les transactions pour les modification par accès SQL
    Set count = 0
    ; Remarque sur Do DISABLE^%NOJRN : 
    ; N'a aucun effet sur : 
    ;   - Un système en miroir.
    ;   - Sur le SQL si $SYSTEM.SQL.Util.SetAutoCommit(0) n'a pas été effectué.
    ;   - Les modifications par accès objet (%Save(),%Delete...) si $SYSTEM.OBJ.SetTransactionMode(0) n'a pas été effectué.
    ; Dans le cas d'un miroir, même si la désactivation des journaux pour le processus n'a pas d'effet,
    ; $SYSTEM.OBJ.SetTransactionMode(0) et $SYSTEM.SQL.Util.SetAutoCommit(0) permet toutefois de limiter 
    ; fortement l'utilisation des journaux dans le cas de la suppression de données.
    ; En effet, les journaux ne contiendront plus que le "Kill" au lieu du "Kill + ancienne valeur".
    Do DISABLE^%NOJRN   ; Désactivation des journaux pour le processus en cours

    Try {
        
        Set date = ##class(%SYSTEM.SQL.Functions).DATEADD("dd", -30, +$Horolog)
        Set date = $Order(^dc.webtiming.log.RequestI("DateTimeI", date), -1)
        Quit:date="" ; There is nothing to delete

        Set lastId = $Order(^dc.webtiming.log.RequestI("DateTimeI", date, ""), -1)
        Quit:lastId="" ; There is nothing to delete

        Set id = ""

        For  {

            Set id = $Order(^dc.webtiming.log.RequestD(id))
            Quit:id=""||(id>=lastId)||(count>Limit)
            
            Do ##class(dc.webtiming.log.Request).%DeleteId(id)

            Set count = count + 1
        }

    } Catch (ex) {
        Set sc = ex.AsStatus()
    }

    Do ENABLE^%NOJRN
    Set tm = $SYSTEM.OBJ.SetTransactionMode(tm) ; restore transaction mode
    Set ac = $SYSTEM.SQL.Util.SetAutoCommit(ac) ; restore autocommit mode

    Return sc
}

}
