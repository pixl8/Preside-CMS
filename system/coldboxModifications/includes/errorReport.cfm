<cfsilent>
	<cfset exception = oException.getExceptionStruct() >
</cfsilent>
<cfthrow object="#exception#">
