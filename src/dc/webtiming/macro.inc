ROUTINE dc.webtiming.macro [Type=INC]

#Define MEASUREVAR      %zMeasure

#Define TOTALHIT        1
#Define GLOREFTOTAL     2
#Define GLOREFMAX       3
#Define TIMINGTOTAL     4
#Define TIMINGMAX       5
#Define LINESTOTAL      6
#Define LINESMAX        7

#Define CURRENTDAYFORURL                3
#Define CURRENTQUARTERFORURL            4

#Def1arg SETLASTERR(%arg)               Set %objlasterror = %arg, ^IRIS.Temp.webtiming("LastError") = $ZDateTime($Horolog, 3, 1) _ " "_ $SYSTEM.Status.GetErrorText(%arg)