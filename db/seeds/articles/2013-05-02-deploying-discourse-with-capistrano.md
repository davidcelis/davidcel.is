---
title: "Deploying Discourse with Capistrano"
date: 2013-05-02 10:42
updated: 2022-12-29 13:08
---

_Note: The Discourse team now provides Docker images that greatly simplify the process of deploying Discourse, so you should just use their [official installation guide](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md). I’ll leave this post up for posterity but, unlike my other posts, I’m unlikely to update or maintain it._

<!--more-->

With the recent release of [Discourse][discourse], an excellent piece of forum software by [Jeff Atwood][jeff-atwood], [Robin Ward][robin-ward] and [Sam Saffron][sam-saffron], I was eager to get an installation up and running myself. With a simple layout it seemed like just what I needed as support and discussion forums for a side project. Discourse is still considered to be squarely in the beta phase, so I had a hard time finding any guides or tutorials that fit my needs for deploying Discourse to a VPS. I did find a [nice tutorial][other-tutorial] by Christopher Baus, but I wanted to get a setup using Capistrano rather than `init.d` because that feels much more Railsy to me. Read on for how I got a Digital Ocean droplet running Discourse on thin with zero-downtime deployments.

## Set up your VPS

_If you’re a Chef wiz and already have some recipes to provision servers for running Rails apps, you can skip ahead to the section on setting up Discourse. Chef is still on my learning TODO list, so I provisioned a server from scratch._

I started with a [Digital Ocean][digital-ocean] droplet running the latest release of Ubuntu 13.04, but presumably any VPS running a recent release (12 04 or 12.10) of Ubuntu should do. Make sure your server has at least 1GB of RAM; you’ll need it to compile all of Discourse’s assets. I chose the 1GB / 1CPU plan, and it’s served me well thus far.

### Secure your server

[Linode][linode] already has an [excellent guide][security] on hiding your server from prying eyes, so I suggest following it to the T. I don’t want to reinvent the wheel here, so this is what I followed exactly. I set my username to `goodbrews` for deploying anything related to that site.

### Change your server’s hostname

Depending on what characters you included in your droplet’s name, DigitalOcean may not set the hostname correctly. To change my server’s hostname, I did the following:

```sh
echo forums.goodbre.ws | sudo tee /etc/hostname
```

Because I deployed my installation to `forums.goodbre.ws`, I changed the first line of my `/etc/hosts/` file to:

```
127.0.0.1 localhost forums.goodbre.ws
```

### Create a swapfile

If you’re running on a VPS service that automatically provisions a swap (such as Linode), you can skip this. On Digital Ocean, however, you’ll need to do this yourself. 1GB of RAM was enough for my first deployment but, when I tried to run a second, I wasn’t able to allocate enough memory to compile assets. Creating a swap, however, has fixed this issue for me. Let’s create a 512MB swapfile:

```sh
sudo dd if=/dev/zero of=/swapfile bs=1024 count=512k
sudo mkswap /swapfile
sudo swapon /swapfile
```

Then, you’ll need to edit `/etc/fstab` and paste in the following line:

```
/swapfile       none    swap    sw      0       0
```

Finally, prevent your swapfile from being readable:

```sh
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile
```

### Install Ruby 2.0.0-p195 and bundler

SSH into your VPS as your deployment user and install the necessary dependencies to build Ruby on Ubuntu:

```sh
sudo apt-get install build-essential openssl libreadline6 libreadline6-dev \
  curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev \
  sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev libgdbm-dev \
  ncurses-dev automake libtool bison subversion pkg-config libffi-dev
```

Now, I personally enjoy using rbenv and ruby-build, so this tutorial will follow installation prodecures around those tools. Feel free to use RVM, chruby, or some other Ruby version manager if you wish.

```sh
# Install rbenv
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv

# Setup rbenv initialization
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

# Restart your shell to use rbenv
exec $SHELL -l

# Install ruby-build
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby 2.0.0-p195 and set it as your user's default
rbenv install 2.0.0-p195; rbenv global 2.0.0-p195
```

_NOTE: the installation guide for `rbenv` mentions using `~/.profile` instead of `~/.bash_profile`, but I found the latter to work for me. You can try either if you have issues._

Finally, you’ll need bundler.

```sh
gem install bundler --no-rdoc --no-ri
```

### Install nginx

I prefer to run my Rails apps under nginx. Plus, Discourse comes with a sample configuration file that requires little tweaking. No brainer!

```sh
sudo apt-get install nginx
```

### Install PostgreSQL, Redis, and other required libraries

Discourse requires [PostgreSQL][postgresql] and [Redis][redis] to run, so let’s install those as well:

```sh
sudo apt-get install postgresql-9.1 postgresql-contrib-9.1 redis-server \
  libxml2-dev libxslt-dev libpq-dev make g++
```

Note that postgresql-contrib-9.1 will install the hstore extension for PostgreSQL, which Discourse requires. You’ll need to create a postgres role and Discourse’s production database:

```sh
# Create your postgres role (I named mine goodbrews, go figure)
sudo -u postgres createuser goodbrews -s -P

# Create discourse's production database (I named mine discourse_production)
createdb -U goodbrews discourse_production
```

And now your VPS should be set up and ready to run Discourse! That means it’s
time to...

## Set up Discourse

Because you’ll need to configure it yourself, Discourse is a prime candidate for [forking][fork-discourse]. If you don’t have Ruby installed on your own computer, yet, I recommend installing rbenv locally. The same steps above will work (or follow rbenv’s [installation guide][install-rbenv]), so make sure you have Ruby 2.0.0-p195 installed.

Then, clone your fork locally (on your own computer).

```sh
git clone git@github.com:$GITHUB_USERNAME/discourse.git
cd discourse
gem install bundler
bundle install
```

### Edit the Discourse configuration files

Copy the sample configuration files...

```sh
cp config/database.yml.sample config/database.yml
cp config/nginx.sample.conf config/nginx.conf
cp config/redis.yml.sample config/redis.yml
cp config/environments/production.sample.rb config/environments/production.rb
```

... and edit them with your own information. `database.yml` should, of course, be edited to use the postgres role that you configured earlier (I also changed the name of the production database to `discourse_production` as I mentioned earlier).

`redis.yml` is unlikely to change if you’ve followed this guide and are running it on the same server.

`production.rb` is where you’ll want to configure how your Discourse installation’s email gets sent out. Personally, I use [Mandrill][mandrill] and configured my app to hit their API.

`nginx.conf` is trickier depending on your needs, however. For instance, I set my discourse installation up to use HTTPS and provisioned SSL certificates from [StartSSL][startssl]. For the purposes of this guide, we’ll stick with basic HTTP. I prefer deploying my applications into the home directory of my deployment user to ensure proper ownership, so my `nginx.conf` file ended up looking like:

```nginx
upstream discourse {
  server unix:///home/goodbrews/discourse/shared/sockets/thin.0.sock max_fails=1 fail_timeout=15s;
  server unix:///home/goodbrews/discourse/shared/sockets/thin.1.sock max_fails=1 fail_timeout=15s;
  server unix:///home/goodbrews/discourse/shared/sockets/thin.2.sock max_fails=1 fail_timeout=15s;
  server unix:///home/goodbrews/discourse/shared/sockets/thin.3.sock max_fails=1 fail_timeout=15s;
}

server {
  listen 80;
  gzip on;
  gzip_min_length 1000;
  gzip_types application/json text/css application/x-javascript;

  server_name forums.goodbre.ws;

  sendfile on;

  keepalive_timeout 65;

  location / {
    root /home/goodbrews/discourse/current/public;

    location ~ ^/t\/[0-9]+\/[0-9]+\/avatar {
      expires 1d;
      add_header Cache-Control public;
      add_header ETag "";
    }

    location ~ ^/assets/ {
      expires 1y;
      add_header Cache-Control public;
      add_header ETag "";
      break;
    }

    proxy_set_header  X-Real-IP  $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Proto $scheme;
    proxy_set_header  Host $http_host;

    # If the file exists as a static file serve it directly without
    # running all the other rewite tests on it
    if (-f $request_filename) {
      break;
    }

    if (!-f $request_filename) {
      proxy_pass http://discourse;
      break;
    }
  }
}
```

The `max_fails=1 fail_timeout=15s` statements on the end of the upstream thin servers is what will help us achieve zero-downtime deployments. As we’re phasing out old thin processes with new ones, any failures on an old thin process will cause nginx to cease handing it requests. It will, instead, hand the request to an old thin process that’s either still running or one of the new thin processes that has already started.

### Configure thin

You’ll also want a thin configuration file to make your life easier:

```sh
thin config -C config/thin.yml --servers 4 -e production
```

This will generate a file, `config/thin.yml`, which you should then go edit. Make sure to set the `chdir`, `log`, `pid`, and `socket` keys to the correct paths. My thin configuration looks like this:

```yaml
---
chdir: /home/goodbrews/discourse/current
environment: production
address: 0.0.0.0
port: 3000
timeout: 30
log: /home/goodbrews/discourse/shared/log/thin.log
pid: /home/goodbrews/discourse/shared/pids/thin.pid
socket: /home/goodbrews/discourse/shared/sockets/thin.sock
max_conns: 1024
max_persistent_conns: 100
require: []
wait: 30
servers: 4
daemonize: true
onebyone: true
```

Make sure you add the `onebyone: true` key. This is the secret sauce that will make your Thin servers restart... You guessed it... One by one. Zero downtime!

### Create a secret token

Discourse doesn’t ship with a secret token set, since it’s not recommended to be version controlled. Therefore, you’ll need to generate one and set it yourself:

```sh
bundle exec rake secret
```

Open up `config/initializers/secret_token.rb` and paste the generated secret
somewhere (probably line 10). You can delete the rest of the file.

### Set up Capistrano

Add the following to Discourse’s `Gemfile`:

```ruby
gem "capistrano", require: nil
gem "capistrano-rbenv", require: nil
```

Create a `Capfile` in Discourse’s root directory:

```ruby
load "deploy" if respond_to?(:namespace)
load "deploy/assets"
Dir["vendor/plugins/*/recipes/*.rb"].each { |plugin| load(plugin) }
load "config/deploy"
```

Create your deployment recipe file at `config/deploy.rb`. Here’s what mine looks like:

```ruby
# Require the necessary Capistrano recipes
require "capistrano-rbenv"
require "bundler/capistrano"
require "sidekiq/capistrano"

# Repository settings, forked to an outside copy
set :repository, "git@github.com:goodbrews/forums.git"
set :deploy_via, :remote_cache
set :branch, fetch(:branch, "master")
set :scm, :git
ssh_options[:forward_agent] = true

# General Settings
set :deploy_type, :deploy
default_run_options[:pty] = true

# Server Settings
set :user, "goodbrews"
set :use_sudo, false
set :rails_env, :production
set :rbenv_ruby_version, "2.0.0-p195"

role :app, "forums.goodbre.ws", primary: true
role :db,  "forums.goodbre.ws", primary: true
role :web, "forums.goodbre.ws", primary: true

# Application Settings
set :application, "discourse"
set :deploy_to, "/home/#{user}/#{application}"

namespace :deploy do
  # Tasks to start, stop and restart thin. This takes Discourse's
  # recommendation of changing the RUBY_GC_MALLOC_LIMIT.
  desc "Start thin servers"
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml start", :pty => false
  end

  desc "Stop thin servers"
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && bundle exec thin -C config/thin.yml stop"
  end

  desc "Restart thin servers"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml restart"
  end

  # Sets up several shared directories for configuration and thin's sockets,
  # as well as uploading your sensitive configuration files to the serer.
  # The uploaded files are ones I've removed from version control since my
  # project is public. This task also symlinks the nginx configuration so, if
  # you change that, re-run this task.
  task :setup_config, roles: :app do
    run  "mkdir -p #{shared_path}/config/initializers"
    run  "mkdir -p #{shared_path}/config/environments"
    run  "mkdir -p #{shared_path}/sockets"
    put  File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    put  File.read("config/redis.yml"), "#{shared_path}/config/redis.yml"
    put  File.read("config/environments/production.rb"), "#{shared_path}/config/environments/production.rb"
    put  File.read("config/initializers/secret_token.rb"), "#{shared_path}/config/initializers/secret_token.rb"
    sudo "ln -nfs #{release_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    puts "Now edit the config files in #{shared_path}."
  end

  # Symlinks all of your uploaded configuration files to where they should be.
  task :symlink_config, roles: :app do
    run  "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run  "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run  "ln -nfs #{shared_path}/config/redis.yml #{release_path}/config/redis.yml"
    run  "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run  "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
  end
end

after "deploy:setup", "deploy:setup_config"
after "deploy:finalize_update", "deploy:symlink_config"

namespace :db do
  desc "Seed your database for the first time"
  task :seed do
    run "cd #{current_path} && psql -d discourse_production < pg_dumps/production-image.sql"
  end
end

after  "deploy:update_code", "deploy:migrate"
```

These should be all of the necessary Capistrano recipes you need to run your first deployment. Let’s do that now!

## Deploy Discourse

Okay, you’ve got your server set up and Discourse configured... Let’s do this!

```sh
# Set up the server's directory structure for Capistrano
cap deploy:setup

# Seed the database you created earlier
cap db:seed

# Do the first deploy! No server is running yet, so do a cold deployment
cap deploy:cold
```

## Configure Discourse

Congratulations! You should now have Discourse running on your VPS. Now that your forums are up and running, you’ll want to follow the [Quick Start Guide][quick-start] that the Discourse team has written up.

## Keeping Discourse up-to-date

You’ll, of course, want to keep your copy of Discourse up-to-date with the main repository. To do so, `cd` into your local copy and set up an upstream remote:

```sh
git remote add upstream git@github.com:discourse/discourse.git
git fetch upstream
git merge upstream/master
git push origin master
cap deploy
```

And there you go. Whenever you want to update, just fetch upstream, merge it into master, push, and redeploy.

### Anything here wrong?

Please let me know if the above steps didn’t work for you. It’s possible that I accidentally left a step out of my process or that the process has changed and I don’t know about it. Reply to [my thread on meta.discourse.org][meta-discourse-thread] where I’ve posted this guide, or shoot me an email using the link at the top.

[digital-ocean]: http://www.digitalocean.com/
[discourse]: http://www.discourse.org/
[docker-installation]: https://github.com/discourse/discourse_docker
[fork-discourse]: https://github.com/discourse/discourse/fork
[install-rbenv]: https://github.com/sstephenson/rbenv
[linode]: http://www.linode.com/
[mandrill]: http://mandrillapp.com/
[meta-discourse-thread]: http://meta.discourse.org/t/deploy-discourse-to-an-ubuntu-vps-using-capistrano/6353
[other-tutorial]: https://github.com/baus/install-discourse
[postgresql]: http://www.postgresql.org
[quick-start]: https://github.com/discourse/discourse/wiki/The-Discourse-Admin-Quick-Start-Guide
[redis]: http://redis.io/
[security]: http://library.linode.com/securing-your-server
[startssl]: https://startssl.com/

[jeff-atwood]: http://codinghorror.com/
[robin-ward]: http://eviltrout.com/
[sam-saffron]: http://samsaffron.com/
