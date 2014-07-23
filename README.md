###Configuring a Rails app to use facebook sign in###

First of all: Im folliwing this tutorial from Rails Casts to do the [implementation of facebook sign in:](http://railscasts.com/episodes/241-simple-omniauth)

Creating the application: `rails new facebook_oauth`  
Moving to the directory: `cd facebook_oauth`  
Add the omniauth gem to your Gemfile: `gem ‘omniauth’`  
In your terminal, run `bundle`    

Create the file `config/initializers/omniauth.rb` and add:    
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do  
    provider :facebook, 'CONSUMER_KEY', 'CONSUMER_SECRET'  
end
```

Substitute the key and secret for the secret and key of your registered application. You’ll need to hide this in the future.

Starting the server `rails s` gives the following error: `warning: already initialized constant APP_PATH`  
I commented the line where the `gem “spring”` is. Looks like this gem is causing the problem. Run `bundle` in terminal. Now I get another error:  

  `Could not find matching strategy for :facebook. You may  need to install an additional gem (such as omniauth-    facebook)`

Addind `gem omniauth-facebook` to `Gemfile`. Running `bundle` in terminal. Running `rails s` on the terminal is now working.

Run in your console `rails g controller StaticPages index`. Modify your `config/routes` file and change the root: `root 'static_page#index'`

Add to `application.html.erb`  
  
`<%= link_to “Sign in with facebook”, “/auth/facebook” %>`  

You also need a route for the callback from facebook. Modify you `config/routes` in  order to create a route:  

`match 'auth/facebook/callback' => 'sessions#create', via: 'get'`  

You need to create a sessions controller: `rails g controller sessions create`
Also you need to create a models for the users: `rails g model user provider:string uid:string name:string`  
(The privider and uid fields seems to be mandatory but the name is optinal and we added here to have some extra info about the user).  
After that we need to migrate the database: `rake db:migrate`  
Inside the `sessions_controller.rb` you need to add to you `create` method:  
```ruby
def create
  auth = request.env["omniauth.auth"]
  user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
end
```  
In this code, `auth` is the data about the user that we get from facebook. You can take a look at it by writing `raise request.env["omniauth.auth"].to_yaml` in the same method in the controller.

We are trying to find a user by two parameters: `provider` and `uid`. If we can not find it, we'll create it using the method `create_with_omniauth` that we'll define in the `User.rb` model class.  

In `models/user.rb`:  
```ruby
def self.create_with_omniauth(auth)
  create! do |user|
    user.provider = auth["provider"]
    user.uid = auth["uid"]
    user.name = auth["info"]["name"]
  end
end
```  
(Careful with syntax errors...)

Add these couple of lines to the `sessions#create` method:  
```ruby
session[:user_id] = user.id
redirect_to root_url, notice: "Signed in"
```  

In your `application_controller.rb`:  
```ruby
helper_method :current_user

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
```
In your `application.html.erb`:  
```ruby
<% if current_user %>
  Welcome, <%= current_user.name%>
  <%= link_to "Sign out", signout_path %
<% else %>
  <%= link_to "Sign in with facebook", "/auth/facebook" %>
<% end %>
```

In your `config/routes.rb`:
```ruby
 match '/signout' => 'sessions#destroy', via: :get, as: :signout
```  

Finally in the `sessions_controller`;
```ruby
def destroy
  session[:user_id] = nil
  redirect_to root_url, notice: "Signed out"
end
```  
In the end, the `gem 'omniauth'` is not neccessary and can be removed from `Gemfile`
  
  
