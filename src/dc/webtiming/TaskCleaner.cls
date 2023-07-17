Class dc.webtiming.TaskCleaner Extends %SYS.Task.Definition
{

Parameter TaskName = "Clean web timing log";

Property LogRetentionInDay As %Integer [ InitialExpression = 30 ];

Property MetricsRetentionInDay As %Integer [ InitialExpression = 180 ];

Method OnTask() As %Status
{
    Set sc = ##class(dc.webtiming.Metrics).CleanMetrics(..MetricsRetentionInDay)
    Return $$$ADDSC(sc, ##class(dc.webtiming.Logger).CleanData(..LogRetentionInDay))
}

ClassMethod install() As %Status
{
	Set sc = $$$OK
	Return:..getTaskId()'="" $$$ERROR($$$GeneralError,"Task already exist")
	Set task = ##class(%SYS.Task).%New()
	Set task.Name=..#TaskName
	Set task.Description="Clean dc_webtiming_log.Requests records."
	Set task.NameSpace=$namespace
	Set task.RunAsUser="_system"
	Set task.TaskClass=..%ClassName(1)
	
	Set task.TimePeriod=0	; every days
	Set task.TimePeriodEvery=1
	Set task.TimePeriodDay=""
	
	Set task.DailyFrequency=0
	Set task.DailyFrequencyTime=""
	Set task.DailyIncrement=""
	Set task.DailyStartTime=4*3600 ; 04:00 a.m.
	Set task.DailyEndTime=""
	
	Set task.Priority=1
	Set sc = task.%Save()
	Return sc
}

ClassMethod getTaskId(
	ByRef sc As %Status = {$$$OK},
	className As %String = {..%ClassName(1)}) As %String
{
	Set id = "", tStatement = ##class(%SQL.Statement).%New()

	$$$ThrowOnError(tStatement.%PrepareClassQuery("%SYS.Task","TaskListDetail"))
	
	Set tResult = tStatement.%Execute()
	
	While (tResult.%Next(.sc)) {
		
		If $$$ISERR(sc) $$$ThrowStatus(sc)

		If tResult.%Get("TaskClass") = className {
			Set id = tResult.%Get("ID")
			Quit
		}
	}
	Quit id
}

}
