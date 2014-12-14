component output=false accessors=true {
	property name="id"                   type="string"  default="";
	property name="name"                 type="string"  default="";
	property name="description"          type="string"  default="";
	property name="viewlet"              type="string"  default="";
	property name="defaultForm"          type="string"  default="";
	property name="addForm"              type="string"  default="";
	property name="editForm"             type="string"  default="";
	property name="presideObject"        type="string"  default="";
	property name="hasHandler"           type="boolean" default=false;
	property name="layouts"              type="string"  default="";
	property name="allowedChildTypes"    type="string"  default="*";
	property name="allowedParentTypes"   type="string"  default="*";
	property name="managedChildTypes"    type="string"  default="";
	property name="showInSiteTree"       type="boolean" default=true;
	property name="siteTemplates"        type="string"  default="*";
	property name="isSystemPageType"     type="boolean" default=false;
	property name="parentSystemPageType" type="string"  default="";

	public boolean function hasHandler() output=false {
		return getHasHandler();
	}
	public boolean function isSystemPageType() output=false {
		return getIsSystemPageType();
	}
	public boolean function showInSiteTree() output=false {
		return getShowInSiteTree();
	}
	public array function listLayouts() output=false {
		return ListToArray( getLayouts() );
	}

	public struct function getMemento(){
		return {
			  id                   = getId()
			, name                 = getName()
			, viewlet              = getViewlet()
			, description          = getDescription()
			, defaultForm          = getDefaultForm()
			, addForm              = getAddForm()
			, editForm             = getEditForm()
			, presideObject        = getPresideObject()
			, hasHandler           = hasHandler()
			, layouts              = listLayouts()
			, allowedChildTypes    = getAllowedChildTypes()
			, allowedParentTypes   = getAllowedParentTypes()
			, managedChildTypes    = getManagedChildTypes()
			, showInSiteTree       = getShowInSiteTree()
			, siteTemplates        = getSiteTemplates()
			, isSystemPageType     = isSystemPageType()
			, parentSystemPageType = getParentSystemPageType()
		};
	}
}