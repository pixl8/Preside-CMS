---
id: 10-8-upgrade-notes
title: Upgrade notes for 10.7 -> 10.8
---

## General notes

The 10.8 release has a small number of changes that require special consideration for upgrade:

* Email centre - creating layouts, migrating SMTP settings and custom system email templates
* Rules engine filters - ensuring auto generated filters make sense
* Task manager exclusivity groups - checking your setup

>>>>> Please ensure that you have read and understood the general [[preparing-for-an-upgrade]] notes that apply to any Preside upgrade.

## Email Centre

### SMTP settings

The one **critical** upgrade note for the 10.8 release is that your old SMTP settings for sending email will need to be manually migrated through the new email centre UI.

After upgrade, navigate to **Email Centre > Settings > SMTP (tab)**. Any previous SMTP server settings should be entered here and saved before email sending will work again.

>>>>>> You may also wish to consider our [Mailgun](https://github.com/pixl8/preside-ext-mailgun) extension for better stats reporting + email sending.

### Create a layout / multiple layouts

If your existing application has programmed an email layout, you should migrate it using the new layouts system, see [[creatingAnEmailLayout]]. This will allow end users to use and configure the layout for custom emails as well as prepare you for migrating your custom system email templates to the new system.

### Migrate system email templates

The [[emailtemplating|legacy email template system]] will continue to work. However, we would advise migrating any templates you have to the new system to make the end-user experience as good as it can be (and avoid future maintenance headaches).

See [[systemEmailTemplates]] for a full guide to creating system email templates in 10.8.0.

## Rules engine filters

The rules engine in general is now **enabled by default** and with that comes the rules engine filter system with auto-generated expressions (you'll notice this in datamanager grids, for example).

### Tidy up

You may wish to go through each of your data table grids and check the filter expressions that are generated for your objects. This may point out gaps in your `i18n` entries for object properties, or reveal some auto generated filters for fields that don't make sense as filters.

To stop an object property from automatically having filter expressions generated, use the `autoFilter` attribute:

```
property name="color" type="string" ... autoFilter=false;
```

### Existing custom expressions

If you are upgrading from 10.7.0 and have existing custom expressions, you may wish to re-evaluate them and **remove them** if there is now an auto generated expression that does the same job (be sure to find out where your expressions are being used and be prepared to fix those saved conditions that are already using them).

## Task manager exclusivity groups

There is now an `@exclusivityGroup` annotation for task manager tasks (see [[taskmanager]]) and its value defaults to the value of the `@displayGroup` of your task.

This means that, by default, after you upgrade to 10.8.0, your exclusivity groups for auto running tasks will match the tabs that you see when you go to the **Task manager** UI in the admin.

What this means is that **no two tasks** in the same exclusivity group will run at the same time when running on a schedule. Before 10.8.0, **no two tasks AT ALL** would run at the same time.

You should check your tasks and ensure that any tasks that should not be run while other specific tasks are running are set to be in the same exclusivity group.
