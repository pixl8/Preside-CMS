component output=false {
	property name="property_a" type="string"  dbtype="varchar"   maxlength=100 required=false default="property_a default";
	property name="property_b" type="date"    dbtype="datetime"                required=false default="cfml:Now()";
	property name="property_c" type="numeric" dbtype="int"                     required=false default="method:CalculatePropC";
	property name="property_d" type="string"  dbtype="varchar"   maxLength=200 required=false default="method:CalculatePropD";

	public numeric function CalculatePropC( required struct data ) output=false {
		return StructCount( arguments.data );
	}

	public string function CalculatePropD( required struct data ) output=false {
		return arguments.data.label ?: "";
	}
}