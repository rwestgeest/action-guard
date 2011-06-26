ActionGuard is a simple authorization module to be used in rails
applications. It well be usable for any other ruby based web framework.

It's been developed as part of some of my own rails application with the
following design principles in mind:

* roles are string values, and role definitions reside in program code,
  not in a database. 
* authorisation rules are collected in one configuration file, rather
  than spreading them out over controller definitions.
* authorisations are on url path matches. In rails' case, you pass
  'fullpath' to the authorization which is then matched against a set of 
  authorisation rules.

# Installing



# Usage

Assuming a Rails application you specify an initializer with the
following content



        role :god , 0
        role :admin, 1
        role :worker, 2

        allow '/'
        allow '/tracking', :at_least => :admin
        allow '/maintenance', :at_least => :worker
        allow '/maintenance/[0-9]*/edit', :at_least => :admin
        allow '/maintenance/[0-9]*$', :at_least => :admin



