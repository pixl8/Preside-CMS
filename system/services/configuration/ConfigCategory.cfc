component accessors=true {
	property name="id"               type="string"  default="";
	property name="name"             type="string"  default="";
	property name="description"      type="string"  default="";
	property name="icon"             type="string"  default="";
	property name="form"             type="string"  default="";
	property name="siteForm"         type="string"  default="";
	property name="tenancy"          type="string"  default="site";
	property name="noTenancy"        type="boolean" default=false;

	public struct function getMemento(){
		return {
			  id          = getId()
			, name        = getName()
			, description = getDescription()
			, icon        = getIcon()
			, form        = getForm()
			, siteForm    = getSiteForm()
			, tenancy     = getTenancy()
			, noTenancy   = getNoTenancy()
		};
	}
}