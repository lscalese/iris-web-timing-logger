Include dc.webtiming.macro

Class dc.webtiming.Measure
{

Parameter DEFAULT = "request";

ClassMethod Start(Name As %String = {..#DEFAULT}) As %Status
{
    Set $$$MEASUREVAR(Name, "timing") = $ZHorolog, 
        $$$MEASUREVAR(Name, "globals") = $$$GlobalRefs,
        $$$MEASUREVAR(Name, "lines") = $SYSTEM.Process.LinesExecuted($Job)
    Return $$$OK
}

ClassMethod Stop(Name As %String = {..#DEFAULT}) As %Status
{
    Set:$Data($$$MEASUREVAR(Name, "lines"), start) $$$MEASUREVAR(Name, "lines") = $SYSTEM.Process.LinesExecuted($Job) - start
    Set:$Data($$$MEASUREVAR(Name, "timing"), start) $$$MEASUREVAR(Name, "timing") = $ZHorolog - start
    Set:$Data($$$MEASUREVAR(Name, "globals"), start) $$$MEASUREVAR(Name, "globals") = $$$GlobalRefs - start
    Return $$$OK
}

ClassMethod GetLines(Name As %String = {..#DEFAULT}) As %Integer [ CodeMode = expression ]
{
$Get($$$MEASUREVAR(Name, "lines"))
}

ClassMethod GetTiming(Name As %String = {..#DEFAULT}) As %Numeric [ CodeMode = expression ]
{
$Get($$$MEASUREVAR(Name, "timing"))*1000
}

ClassMethod GetGlobals(Name As %String = {..#DEFAULT}) As %Integer [ CodeMode = expression ]
{
$Get($$$MEASUREVAR(Name, "globals"))
}

ClassMethod AddGlobals(
	Name As %String = {..#DEFAULT},
	toAdd As %Integer = 0)
{
    Quit:'$Data($$$MEASUREVAR(Name, "globals"), start)
    Set $$$MEASUREVAR(Name, "globals") = start - toAdd
    Quit
}

ClassMethod SetCleanURL(
	URL As %String,
	Name As %String = {..#DEFAULT}) As %Status
{
    Set matcher = ##class(%Regex.Matcher).%New("\/[0-9]{1,}"),
        matcher.Text = $Piece(URL, "?", 1),  ; $Piece to exclude query string parameters
        $$$MEASUREVAR(Name, "clean_url") = matcher.ReplaceAll("/<parameter>")
    Return $$$OK
}

ClassMethod GetCleanURL(Name As %String = {..#DEFAULT}) As %String [ CodeMode = expression ]
{
$Get($$$MEASUREVAR(Name, "clean_url"))
}

}
