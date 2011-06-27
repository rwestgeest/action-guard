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

# Documentation

Documentation is work in progress. PLease this besides this readme, you
can  read the
[specs](https://github.com/rwestgeest/action-guard/tree/master/spec)
and find the rdoc here:

http://rubydoc.info/gems/action-guard

# Installing

        gem install action-guard 

or put action-guard in your Gemfile and 

        bundle install

# Getting started

Assuming a Rails application, you specify an initializer with the
following content:

        ActionGuard.load_from_file(File.join(Rails.root, 'config', 'authorization.rules'))

and a file called authorization.rules in the config directory with
something like:

        role :god , 0
        role :admin, 1
        role :worker, 2

        allow '/'
        allow '/tracking', :only_by => :admin
        allow '/maintenance', :at_least => :worker
        allow '/maintenance/[0-9]*/edit', :at_least => :admin
        allow '/maintenance/[0-9]*$', :at_least => :admin

and some model with a string typed attribute called 'role', in an
account or user model e.g.:

        class Account
          attr_reader :role
        end

then in your (Application) controller you can

        class ApplicationController < ActionController::Base
          prepend_before_filter :authorize_action

          protected
          def authorized?(fullpath)
            ActionGuard.authorized?(current_account, fullpath)
          end
          helper_method :authorized?

          private
          def authorize_action
            unless authorized?(request.fullpath)
              flash[:alert] = I18n.t("not_authorized")
              sign_out current_account if current_account
              redirect_to new_account_session_path
            end
          end
        end

(In the example above, the path helpers, sign_out and current_account
methods are from [Devise]i(https://github.com/plataformatec/devise))

This is in essence all you need to get actionguard working. You could
also hide non authorized linkes by adding an authorized_link_to method
like so:

      def authorized_link_to(what, path, options = {})
        if (authorized?(path)) 
          link_to(what, path, options)
        end
      end

or overwrite link_to

# Issues - bugs

If you find any issues in the code please let me know through:

https://github.com/rwestgeest/action-guard/issues

also consult that list for known issues in ActionGuard

