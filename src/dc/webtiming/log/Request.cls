Class dc.webtiming.log.Request Extends %Persistent
{

Property DateTime As %TimeStamp [ InitialExpression = {$ZDateTime($Horolog, 3, 1)}, Required ];

Property Login As %String(TRUNCATE = 1);

Property Gloref As %Integer;

Property Lines As %Integer;

Property TimingInMs As %Float;

Property Method As %Integer(DISPLAYLIST = ",GET,HEAD,POST,PUT,DELETE,CONNECT,OPTIONS,TRACE,PATCH", VALUELIST = ",1,2,3,4,5,6,7,8,9");

Property Timer As %String(TRUNCATE = 1);

Property IP As %String(TRUNCATE = 1);

Property HttpStatusCode As %String(TRUNCATE = 1);

Property URL As %String(MAXLEN = "", TRUNCATE = 1);

Property Namespace As %String [ InitialExpression = {$Namespace} ];

Property PageName As %String(MAXLEN = "", TRUNCATE = 1);

Property Application As %String(MAXLEN = "", TRUNCATE = 1);

Property URLClean As %String(MAXLEN = "", TRUNCATE = 1);

Index DateTimeI On DateTime;

Index LoginI On Login [ Type = bitmap ];

Index PageNameI On PageName [ Type = bitmap ];

Storage Default
{
<Data name="RequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DateTime</Value>
</Value>
<Value name="3">
<Value>Login</Value>
</Value>
<Value name="4">
<Value>Gloref</Value>
</Value>
<Value name="5">
<Value>Lines</Value>
</Value>
<Value name="6">
<Value>Timing</Value>
</Value>
<Value name="7">
<Value>Method</Value>
</Value>
<Value name="8">
<Value>Timer</Value>
</Value>
<Value name="9">
<Value>IP</Value>
</Value>
<Value name="10">
<Value>HttpStatusCode</Value>
</Value>
<Value name="11">
<Value>URL</Value>
</Value>
<Value name="12">
<Value>TimingInMs</Value>
</Value>
<Value name="13">
<Value>Namespace</Value>
</Value>
<Value name="14">
<Value>PageName</Value>
</Value>
<Value name="15">
<Value>Application</Value>
</Value>
<Value name="16">
<Value>URLClean</Value>
</Value>
</Data>
<DataLocation>^dc.webtiming.log.RequestD</DataLocation>
<DefaultData>RequestDefaultData</DefaultData>
<IdLocation>^dc.webtiming.log.RequestD</IdLocation>
<IndexLocation>^dc.webtiming.log.RequestI</IndexLocation>
<StreamLocation>^dc.webtiming.log.RequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
