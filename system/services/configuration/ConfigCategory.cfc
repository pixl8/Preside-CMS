component output=false accessors=true {
	property name="id"               type="string"  default="";
	property name="name"             type="string"  default="";
	property name="description"      type="string"  default="";
	property name="icon"             type="string"  default="";
	property name="form"             type="string"  default="";
	property name="siteForm"         type="string"  default="";

	public struct function getMemento(){
		return {
			  id          = getId()
			, name        = getName()
			, description = getDescription()
			, icon        = getIcon()
			, form        = getForm()
			, siteForm    = getSiteForm()
		};
	}
}