component output=false accessors=true {
	property name="fieldName"       type="string" default="";
	property name="validator"       type="string" default="";
	property name="params"          type="struct" default=StructNew();
	property name="message"         type="string" default="";
	property name="serverCondition" type="string" default="";
	property name="clientCondition" type="string" default="";

	public struct function getMemento(){
		return {
			  fieldName       = getFieldName()
			, validator       = getValidator()
			, params          = getParams()
			, message         = getMessage()
			, serverCondition = getServerCondition()
			, clientCondition = getClientCondition()
		}
	}
}