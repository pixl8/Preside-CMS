component output=false accessors=true {
	property name="id"            type="string" default="";
	property name="name"          type="string" default="";
	property name="handler"       type="string" default="";
	property name="defaultAction" type="string" default="";
	property name="configForm"    type="string" default="";

	public struct function getMemento(){
		return {
			  id            = getId()
			, name          = getName()
			, handler       = getHandler()
			, defaultAction = getDefaultAction()
			, configForm    = getConfigForm()
		};
	}
}