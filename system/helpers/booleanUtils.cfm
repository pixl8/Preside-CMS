<cfscript>
	public boolean function isTrue( any someValue ) output=false { silent {
		return IsBoolean( arguments.someValue ) && arguments.someValue;
	} }

	public boolean function isFalse( any someValue ) output=false { silent {
		return !IsBoolean( arguments.someValue ) || !arguments.someValue;
	} }
</cfscript>