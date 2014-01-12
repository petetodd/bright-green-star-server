bright-green-star-server
========================

A rails server with devise security that will respond to json requests from an iOS app (see bright-green-star-client).   
Rails version 4.0.2
Ruby 2.0.0

You can just download and run the server, but if you want to build from scratch follow this (and refer to the code as needed).

Create the Rails app

rails new bgsserver 

#Gemfile changes

You could test the app using sqlite but I use mysql on both my development and production environments.
Replace sqlite3 with

gem 'mysql2'

Capistrano Deployment
I use Capistrano to deploy my apps - but this demo doesn't detail that so you could ignore the following 3 gems 

gem 'capistrano', '~> 3.0.1'

gem 'capistrano-bundler'

(and also include a javascript runtime, I use therubyracer)

gem 'therubyracer'

Devise Security

gem 'devise'

That completes the gemfile changes, just run “bundle install”.

#Update database.yml

[Only necessary if you’ve decided to use MySql]

As we are using mysql we need to configure the mysql database in our app.  Do this by replacing /config/database.yml with something similar to the example in the demo app.

#Devise Configuration
We want devise security to enable the following

1. The user can create a bgsserver account.

2. The user can create a new Trip.

3. The user can only view their trip and not the trips created by other users.

We will implement this functionality on bgsserver and test using curl, we will then implement this on the bgsclient app.

<h3>Install</h3>

rails generate devise:install

Review the instructions and setup as appropriate.
[In this demo I’ve ignored these instructions as I don’t want to setup a mailer and I’m not concerned about presenting nice html view]

<h3>Create USER model</h3>

rails generate devise User

Run a migration rake db:migrate

<h3>Register a new user</h3>

The following curl statement should register a new user:

<b><i>curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d ' {"user":{"email":"testuser@testerusersomeramdonthig=ng.com","password":"tester99"}}'  http://localhost:3000/users </b></i>

BUT this will fail with a CSRF error.

To deal with this we customize the RegistrationsController.

Create a folder apps/controllers/users

Create a file in this folder call registrations_controller.rb and paste in the following

    class Users::RegistrationsController  < Devise::RegistrationsController
       skip_before_filter :verify_authenticity_token
       respond_to :json
       
       def create
          user = User.new(user_params)
          if user.save
             render :json => user.as_json( :email=>user.email), :status=>201
             return
          else
             warden.custom_failure!
             render :json => user.errors, :status=>422
      end
    end
    
    def user_params
    params.require(:user).permit(:email, :password)
    end
    end

Amend routes.rb with a path to this controller
  devise_for :users, :controllers => { :registrations => "users/registrations" }
 # devise_for :users

Registration of a new user using the above curl statement will now work.

#Create a new trip with JSON call

    curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"trip":{"name":"Demo Trip 1","typetrip":"A test type"}}'  http://localhost:3000/trips

This will fail with a CSRF error.

Add the following to the TripsController class

    skip_before_filter :verify_authenticity_token, :only => [ :create, :update]

Try the curl statement again and it should work.

#Create a new trip with JSON call - owned by User

We can successfully create a new Trip but it is not owned by the user. 

1. To do this we need to set the relationship in rails 
2. Require user authentication before giving access to create Trips
 
<h3>Set the relationships</h3>

In trip model (trip.rb) add the following
     belongs_to :users

Create a migration to implement this on the database:

    rails g migration AddUserIdToTrips user_id:integer

Also add a has_many relationship in the User model (this allows us to easily retrieve all the Trips owned by a user).

    has_many :trips

<h2>Add an authenticate_user filter</h2>
To require the user to be logged in add the following to TripsController

      before_filter :authenticate_bgs_user!
      
      def authenticate_bgs_user!
      unless current_user
          headers["WWW-Authenticate"] = %(Basic realm="My Realm")          
          render :json => {:message =>I18n.t("errors.messages.authorization_error")}, :status => :unauthorized
      end
    end

TEST Use cURL to create a new Trip owned by User

The following should now return an Unauthorized (401)error

      curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"trip":{"name":"Demo Trip 1","typetrip":"A test type"}}'  http://localhost:3000/trips

To make this work we need to logon before we create the trip and save the cookie and use the cookie in a Trip post.

The following should do the logon and save the cookie for reuse.

    curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"user":{"email":"testuser@testeruser.com","password":"tester99"}}'  http://localhost:3000//users/sign_in -c cookiefile

But this fails with a CSRF error.

To deal with this we need to customise the sessions controller (similar to has we did for Registrations controller).

Create a new file sessions_controller in app/controllers/users

    class Users::SessionsController < Devise::SessionsController

      skip_before_filter :verify_authenticity_token
      respond_to :json
    end

You must include the “respond_to :json” line as recent versions of devise don’t seem to handle json by default in the sessions_controller.

Test again using the following and a trip should be created (will use the saved “cookiefile”) to register

    curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"trip":{"name":"Demo Trip 1","typetrip":"A test type"}}'  http://localhost:3000/trips -b cookiefile

But this is still not “owned” by user.

Update the Trip model create method:

    def create
      @trip = Trip.new(trip_params)
      @trip.user_id = current_user.id

and also add the :user_id to the accepted params:

    def trip_params
      params.require(:trip).permit(:name, :typetrip, :content, :user_id)
    end

Now when you save a trip its all working.

Time to implement this in the iOS app.  Out iOS functionality will do all that the cURL tests did (and more!).







