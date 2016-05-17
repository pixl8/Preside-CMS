---
id: presideforms-presideobjects
title: Using Preside data objects with form definitions
---

## Using Preside data objects with form definitions

### Field bindings

The `binding` attribute on field definitions allows you to pull in attributes and i18n defaults from preside object properties:

```xml
<field binding="page.title" />
```

In the example above, the field's definition will be taken from the `title` property of the `page` object (CFC file). A default [[presideforms-controls|form control]] will be assigned to the field based on the property type and other attributes. The title, help and placeholder will be defaulted to `preside-objects.page:field.title.title`, `preside-objects.page:field.title.help` and `preside-objects.page:field.title.placeholder`.

### Default forms

If you attempt to make use of a form that does not have an XML definition and who's name starts with "preside-objects.name_of_object.", a default form will be returned based on the preside object CFC file (in this case, "name_of_object"). 

For example, if there is no `/forms/preside-objects/blog_category/admin.add.xml` file defined and we do something like the call below, an automatic form definition will be used based on the `blog_category` preside object:

```luceescript
renderForm( ... formName="preside-objects.blog_category.admin.add", ... );
```

A notable use of this convention is in the Data Manager where you can create simple object definitions and just use their default form for adding and editing records. 
