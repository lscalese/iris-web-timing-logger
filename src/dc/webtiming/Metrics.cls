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
    Set url = ""

    Try{
        For  {
            Set url = $Order(^dc.webtiming.Metrics(url))
            Quit:url=""

            Lock +^dc.webtiming.Metrics(url, date)

            Set currentDayData = $Get(^dc.webtiming.Metrics(url, date))
            Set currentQuarterData = $Get(^dc.webtiming.Metrics(url, date, part))

            Lock -^dc.webtiming.Metrics(url, date)

            Set suffix(1) = "", suffix(2) = "_current_quarter", i = 0

            For tmpData = currentDayData, currentQuarterData {
                
                Set totalHit = +$ListGet(tmpData, $$$TOTALHIT), suffix = suffix($Increment(i))

                Do ..SetSensor(..#GLOREFTOTAL _ suffix, +$ListGet(tmpData, $$$GLOREFTOTAL), url)
                Do ..SetSensor(..#TIMINGTOTAL _ suffix, +$ListGet(tmpData, $$$TIMINGTOTAL), url)
                Do ..SetSensor(..#LINESTOTAL _ suffix, +$ListGet(tmpData, $$$LINESTOTAL), url)
                Do ..SetSensor(..#TIMINGMAX _ suffix, +$ListGet(tmpData, $$$TIMINGMAX), url)
                Do ..SetSensor(..#LINESMAX _ suffix, +$ListGet(tmpData, $$$LINESMAX), url)
                Do ..SetSensor(..#TOTALHIT _ suffix, totalHit, url)
                

                Continue:totalHit'>0   
                
                Do ..SetSensor(..#GLOREFAVG _ suffix, +$ListGet(tmpData, $$$GLOREFTOTAL) / totalHit, url)
                Do ..SetSensor(..#TIMINGAVG _ suffix, +$ListGet(tmpData, $$$TIMINGTOTAL) / totalHit, url)
                Do ..SetSensor(..#LINESAVG _ suffix, +$ListGet(tmpData, $$$LINESTOTAL) / totalHit, url)
                
            }
            
        }
    }catch (ex) {
        s ^CacheTempLsc= ex.AsStatus()
    }

    Return $$$OK
}

ClassMethod SetMetrics(Application As %String = {$Select($IsObject($Get(%request)):%request.Application, 1:"")}) As %Status
{
    If $Get(Application) = "" Return $$$ERROR(5001, "Parameter ""Application"" is mandatory")

    Set tHorolog = $Horolog, date = $ZDate(tHorolog, 3), part = $Piece(tHorolog, ",", 2) \ ..#PART, sc = $$$OK
    
    Set gloRef = ##class(dc.webtiming.Measure).GetGlobals(),
        timing = ##class(dc.webtiming.Measure).GetTiming(),
        lines = ##class(dc.webtiming.Measure).GetLines(),
        url = ##class(dc.webtiming.Measure).GetCleanURL()
    
    Set:url="" url = " " ; shouldn't occur but it's just <subscript> error security.

    Set urlMetricsEnabled = ##class(dc.webtiming.Config).IsURLMetricsEnabled()

    Lock +^dc.webtiming.Metrics(Application, date):2
    
    If '$Test Return $$$ERROR(5001, "Failed to acquire an exclusive lock.")

    Try {

        Set data($$$CURRENTDAYFORAPPLICATION) = $Get(^dc.webtiming.Metrics(Application, date)),
            data($$$CURRENTQUARTERFORAPPLICATION) = $Get(^dc.webtiming.Metrics(Application, date, part))
        
        If urlMetricsEnabled {
            Set data($$$CURRENTDAYFORURL) = $Get(^dc.webtiming.Metrics(url, date)),
                data($$$CURRENTQUARTERFORURL) = $Get(^dc.webtiming.Metrics(url, date, part))
        }

        Set key = ""

        For  {
            Set key = $Order(data(key), 1, tmp)
            Quit:key=""
            
            Set $List(tmp, $$$GLOREFTOTAL) = +$ListGet(tmp, $$$GLOREFTOTAL) + gloRef,
                $List(tmp, $$$TIMINGTOTAL) = +$ListGet(tmp, $$$TIMINGTOTAL) + timing,
                $List(tmp, $$$LINESTOTAL) = +$ListGet(tmp, $$$LINESTOTAL) + lines,
                $List(tmp, $$$TOTALHIT) = +$ListGet(tmp, $$$TOTALHIT) + 1

            If gloRef > +$ListGet(tmp, $$$GLOREFMAX) Set $List(tmp, $$$GLOREFMAX) = gloRef
            If timing > +$ListGet(tmp, $$$TIMINGMAX) Set $List(tmp, $$$TIMINGMAX) = timing
            If lines > +$ListGet(tmp, $$$LINESMAX) Set $List(tmp, $$$LINESMAX) = lines

            Set data(key) = tmp
        }

        Set ^dc.webtiming.Metrics(Application, date) = data($$$CURRENTDAYFORAPPLICATION),
            ^dc.webtiming.Metrics(Application, date, part) = data($$$CURRENTQUARTERFORAPPLICATION)
        
        If urlMetricsEnabled {
            Set ^dc.webtiming.Metrics(url, date) = data($$$CURRENTDAYFORURL),
                ^dc.webtiming.Metrics(url, date, part) = data($$$CURRENTQUARTERFORURL)
        }

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
