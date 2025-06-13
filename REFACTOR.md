# BIG CHANGES

- Units model is minimal
- Inspections model has removed a bunch of duplicate attributes that were also in assessments
- i18n keys have been moved to forms.name.* - they are flat beyond that - no "fields" namespace. "title" for the form title is now "header"
- we use the form_context partial to generate the @_current_form and @_current_i18n_base variables - the other partials inherit from those
- we should NOT add "form" and "i18n_base" attributes to fieldsets - thats outdated. instead they should inherit from the form

