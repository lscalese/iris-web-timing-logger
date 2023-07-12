Include dc.webtiming.macro

Class dc.webtiming.Metrics Extends %SYS.Monitor.SAM.Abstract
{

Parameter PRODUCT = "webmeasure";

Parameter GLOREFTOTAL = "total_gloref";

Parameter GLOREFAVG = "average_gloref";

Parameter GLOREFMAX = "max_gloref";

Parameter TIMINGTOTAL = "total_timing_in_ms";

Parameter TIMINGAVG = "average_timing_in_ms";

Parameter TIMINGMAX = "max_timing";

Parameter LINESTOTAL = "total_lines";

Parameter LINESAVG = "average_lines";

Parameter LINESMAX = "max_lines";

Parameter TOTALHIT = "total_hit";

Parameter PART = 900;

Method GetSensors() As %Status
{
    Set date = $ZDate($Horolog, 3), part = $Piece($HOROLOG, ",", 2) \ ..#PART
    
    Do ..GetWebAppSensors(date, part)

    Quit $$$OK
}

Method GetWebAppSensors(
	date As %String = { $ZDate($Horolog, 3)},
	part As %String = { $Piece($HOROLOG, ",", 2) \ ..#PART}) As %Status
{
    Set webapp = ""

    For  {
        Set webapp = $Order(^dc.webtiming.Metrics(webapp))
        Quit:webapp=""

        Lock +^dc.webtiming.Metrics(webapp, date)

        Set currentDayData = $Get(^dc.webtiming.Metrics(webapp, date))
        Set currentQuarterData = $Get(^dc.webtiming.Metrics(webapp, date, part))

        Lock -^dc.webtiming.Metrics(webapp, date)

        Set suffix(1) = "", suffix(2) = "_current_quarter"

        For tmpData = currentDayData, currentQuarterData {
            
            Set totalHit = +$ListGet(tmpData, $$$TOTALHIT), suffix = suffix($Increment(i))

            Do ..SetSensor(..#GLOREFTOTAL _ suffix, +$ListGet(tmpData, $$$GLOREFTOTAL), webapp)
            Do ..SetSensor(..#TIMINGTOTAL _ suffix, +$ListGet(tmpData, $$$TIMINGTOTAL), webapp)
            Do ..SetSensor(..#LINESTOTAL _ suffix, +$ListGet(tmpData, $$$LINESTOTAL), webapp)
            Do ..SetSensor(..#TIMINGMAX _ suffix, +$ListGet(tmpData, $$$TIMINGMAX), webapp)
            Do ..SetSensor(..#LINESMAX _ suffix, +$ListGet(tmpData, $$$LINESMAX), webapp)
            Do ..SetSensor(..#TOTALHIT _ suffix, totalHit, webapp)
            

            Continue:totalHit'>0   
            
            Do ..SetSensor(..#GLOREFAVG _ suffix, +$ListGet(tmpData, $$$GLOREFTOTAL) / totalHit, webapp)
            Do ..SetSensor(..#TIMINGAVG _ suffix, +$ListGet(tmpData, $$$TIMINGTOTAL) / totalHit, webapp)
            Do ..SetSensor(..#LINESAVG _ suffix, +$ListGet(tmpData, $$$LINESTOTAL) / totalHit, webapp)
            
        }
        
    }
    
    Return $$$OK
}

ClassMethod SetMetrics(Application As %String = {$Select($IsObject($Get(%request)):%request.Application, 1:"")}) As %Status
{
    If $Get(Application) = "" Return $$$ERROR(5001, "Parameter ""Application"" is mandatory")

    Set tHorolog = $Horolog, date = $ZDate(tHorolog, 3), part = $Piece(tHorolog, ",", 2) \ ..#PART, sc = $$$OK

    Lock +^dc.webtiming.Metrics(Application, date):2
    
    If '$Test Return $$$ERROR(5001, "Failed to acquire an exclusive lock.")

    Try {

        Set currentDayData = $Get(^dc.webtiming.Metrics(Application, date))
        Set currentQuarterData = $Get(^dc.webtiming.Metrics(Application, date, part))
        
        Set gloRef = ##class(dc.webtiming.Measure).GetGlobals()
        Set timing = ##class(dc.webtiming.Measure).GetTiming()
        Set lines = ##class(dc.webtiming.Measure).GetLines()

        Set $List(currentDayData, $$$GLOREFTOTAL) = +$ListGet(currentDayData, $$$GLOREFTOTAL) + gloRef
        Set $List(currentDayData, $$$TIMINGTOTAL) = +$ListGet(currentDayData, $$$TIMINGTOTAL) + timing
        Set $List(currentDayData, $$$LINESTOTAL) = +$ListGet(currentDayData, $$$LINESTOTAL) + lines
        Set $List(currentDayData, $$$TOTALHIT) = +$ListGet(currentDayData, $$$TOTALHIT) + 1

        If gloRef > +$ListGet(currentDayData, $$$GLOREFMAX) Set $List(currentDayData, $$$GLOREFMAX) = gloRef
        If timing > +$ListGet(currentDayData, $$$TIMINGMAX) Set $List(currentDayData, $$$TIMINGMAX) = timing
        If lines > +$ListGet(currentDayData, $$$LINESMAX) Set $List(currentDayData, $$$LINESMAX) = lines
        

        Set $List(currentQuarterData, $$$GLOREFTOTAL) = +$ListGet(currentQuarterData, $$$GLOREFTOTAL) + gloRef
        Set $List(currentQuarterData, $$$TIMINGTOTAL) = +$ListGet(currentQuarterData, $$$TIMINGTOTAL) + timing
        Set $List(currentQuarterData, $$$LINESTOTAL) = +$ListGet(currentQuarterData, $$$LINESTOTAL) + lines
        Set $List(currentQuarterData, $$$TOTALHIT) = +$ListGet(currentQuarterData, $$$TOTALHIT) + 1
        
        If gloRef > +$ListGet(currentQuarterData, $$$GLOREFMAX) Set $List(currentQuarterData, $$$GLOREFMAX) = gloRef
        If timing > +$ListGet(currentQuarterData, $$$TIMINGMAX) Set $List(currentQuarterData, $$$TIMINGMAX) = timing
        If lines > +$ListGet(currentQuarterData, $$$LINESMAX) Set $List(currentQuarterData, $$$LINESMAX) = lines

        Set ^dc.webtiming.Metrics(Application, date) = currentDayData
        Set ^dc.webtiming.Metrics(Application, date, part) = currentQuarterData

        Lock -^dc.webtiming.Metrics(Application, date)

    } Catch(ex) {

        Lock -^dc.webtiming.Metrics(Application, date)
        Set sc = ex.AsStatus()
    }

    Return sc
}

ClassMethod PurgeMetrics() As %Status
{
    Lock +^dc.webtiming.Metrics:2
    If '$Test Return $$$ERROR(5001, "Failed to acquire an exclusive lock.")

    Kill ^dc.webtiming.Metrics

    Lock -^dc.webtiming.Metrics
    
    Return $$$OK
}

ClassMethod CleanMetrics(RetentionInDay As %Integer = 180) As %Status
{
    Set sc = $$$OK
    
    Set limitDate = $Piece($SYSTEM.SQL.Functions.DATEADD("dd", -RetentionInDay, $Horolog), " ", 1)

    Set application = ""

    For  {
        Set application = $Order(^dc.webtiming.Metrics(application))
        Quit:application=""

        Set date = ""
        For  {
            Set date = $Order(^dc.webtiming.Metrics(application, date))
            Quit:date=""||(date]]limitDate)

            Kill ^dc.webtiming.Metrics(application, date)
        }

    }

    Return sc
}

}
