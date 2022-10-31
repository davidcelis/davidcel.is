---
layout: post
title: "Deploying Discourse with Capistrano"
date: 2013-05-02 10:42
categories: [programming, ruby, rails, discourse]
redirect_from:
  - /blog/2013/05/02/deploying-discourse-with-capistrano/
---

_UPDATE: You should definitely be using the official [Docker installation method][docker-installation] provided by the Discourse team._

With the recent release of [Discourse][discourse], an excellent piece of forum software by [Jeff Atwood][jeff-atwood], [Robin Ward][robin-ward] and [Sam Saffron][sam-saffron], I was eager to get an installation up and running myself. With a simple layout it seemed like just what I needed as support and discussion forums for a side project. Discourse is still considered to be squarely in the beta phase, so I had a hard time finding any guides or tutorials that fit my needs for deploying Discourse to a VPS. I did find a [nice tutorial][other-tutorial] by Christopher Baus, but I wanted to get a setup using Capistrano rather than `init.d` because that feels much more Railsy to me. Read on for how I got a Digital Ocean droplet running Discourse on thin with zero-downtime deployments.

## Set up your VPS

_If you're a Chef wiz and already have some recipes to provision servers for running Rails apps, you can skip ahead to the section on setting up Discourse. Chef is still on my learning TODO list, so I provisioned a server from scratch._

I started with a [Digital Ocean][digital-ocean] droplet running the latest release of Ubuntu 13.04, but presumably any VPS running a recent release (12 04 or 12.10) of Ubuntu should do. Make sure your server has at least 1GB of RAM; you'll need it to compile all of Discourse's assets. I chose the 1GB / 1CPU plan, and it's served me well thus far.

### Secure your server

[Linode][linode] already has an [excellent guide][security] on hiding your server from prying eyes, so I suggest following it to the T. I don't want to reinvent the wheel here, so this is what I followed exactly. I set my username to `goodbrews` for deploying anything related to that site.

### Change your server's hostname

Depending on what characters you included in your droplet's name, DigitalOcean may not set the hostname correctly. To change my server's hostname, I did the following:

{% gist davidcelis/6f2b367bf12509a6c9c4 hostname.sh %}

Because I deployed my installation to `forums.goodbre.ws`, I changed the first line of my `/etc/hosts/` file to:

{% gist davidcelis/6f2b367bf12509a6c9c4 hosts %}

### Create a swapfile

If you're running on a VPS service that automatically provisions a swap (such as Linode), you can skip this. On Digital Ocean, however, you'll need to do this yourself. 1GB of RAM was enough for my first deployment but, when I tried to run a second, I wasn't able to allocate enough memory to compile assets. Creating a swap, however, has fixed this issue for me. Let's create a 512MB swapfile:

{% gist davidcelis/6f2b367bf12509a6c9c4 swap.sh %}

Then, you'll need to edit `/etc/fstab` and paste in the following line:

{% gist davidcelis/6f2b367bf12509a6c9c4 fstab %}

Finally, prevent your swapfile from being readable:

{% gist davidcelis/6f2b367bf12509a6c9c4 hide_swapfile.sh %}

### Install Ruby 2.0.0-p195 and bundler

SSH into your VPS as your deployment user and install the necessary dependencies to build Ruby on Ubuntu:

{% gist davidcelis/6f2b367bf12509a6c9c4 apt_get.sh %}

Now, I personally enjoy using rbenv and ruby-build, so this tutorial will follow installation prodecures around those tools. Feel free to use RVM, chruby, or some other Ruby version manager if you wish.

{% gist davidcelis/6f2b367bf12509a6c9c4 ruby.sh %}

_NOTE: the installation guide for `rbenv` mentions using `~/.profile` instead of `~/.bash_profile`, but I found the latter to work for me. You can try either if you have issues._

Finally, you'll need bundler.

{% gist davidcelis/6f2b367bf12509a6c9c4 bundler.sh %}

### Install nginx

I prefer to run my Rails apps under nginx. Plus, Discourse comes with a sample configuration file that requires little tweaking. No brainer!

{% gist davidcelis/6f2b367bf12509a6c9c4 nginx.sh %}

### Install PostgreSQL, Redis, and other required libraries

Discourse requires [PostgreSQL][postgresql] and [Redis][redis] to run, so let's install those as well:

{% gist davidcelis/6f2b367bf12509a6c9c4 apt_get_2.sh %}

Note that postgresql-contrib-9.1 will install the hstore extension for PostgreSQL, which Discourse requires. You'll need to create a postgres role and Discourse's production database:

{% gist davidcelis/6f2b367bf12509a6c9c4 postgres.sh %}

And now your VPS should be set up and ready to run Discourse! That means it's
time to...

## Set up Discourse

Because you'll need to configure it yourself, Discourse is a prime candidate for [forking][fork-discourse]. If you don't have Ruby installed on your own computer, yet, I recommend installing rbenv locally. The same steps above will work (or follow rbenv's [installation guide][install-rbenv]), so make sure you have Ruby 2.0.0-p195 installed.

Then, clone your fork locally (on your own computer).

{% gist davidcelis/6f2b367bf12509a6c9c4 clone.sh %}

### Edit the Discourse configuration files

Copy the sample configuration files...

{% gist davidcelis/6f2b367bf12509a6c9c4 copy_config.sh %}

... and edit them with your own information. `database.yml` should, of course, be edited to use the postgres role that you configured earlier (I also changed the name of the production database to `discourse_production` as I mentioned earlier).

`redis.yml` is unlikely to change if you've followed this guide and are running it on the same server.

`production.rb` is where you'll want to configure how your Discourse installation's email gets sent out. Personally, I use [Mandrill][mandrill] and configured my app to hit their API.

`nginx.conf` is trickier depending on your needs, however. For instance, I set my discourse installation up to use HTTPS and provisioned SSL certificates from [StartSSL][startssl]. For the purposes of this guide, we'll stick with basic HTTP. I prefer deploying my applications into the home directory of my deployment user to ensure proper ownership, so my `nginx.conf` file ended up looking like:

{% gist davidcelis/6f2b367bf12509a6c9c4 nginx.conf %}

The `max_fails=1 fail_timeout=15s` statements on the end of the upstream thin servers is what will help us achieve zero-downtime deployments. As we're phasing out old thin processes with new ones, any failures on an old thin process will cause nginx to cease handing it requests. It will, instead, hand the request to an old thin process that's either still running or one of the new thin processes that has already started.

### Configure thin

You'll also want a thin configuration file to make your life easier:

{% gist davidcelis/6f2b367bf12509a6c9c4 thin.sh %}

This will generate a file, `config/thin.yml`, which you should then go edit. Make sure to set the `chdir`, `log`, `pid`, and `socket` keys to the correct paths. My thin configuration looks like this:

{% gist davidcelis/6f2b367bf12509a6c9c4 thin.yml %}

Make sure you add the `onebyone: true` key. This is the secret sauce that will make your Thin servers restart... You guessed it... One by one. Zero downtime!

### Create a secret token

Discourse doesn't ship with a secret token set, since it's not recommended to be version controlled. Therefore, you'll need to generate one and set it yourself:

{% gist davidcelis/6f2b367bf12509a6c9c4 secret.sh %}

Open up `config/initializers/secret_token.rb` and paste the generated secret
somewhere (probably line 10). You can delete the rest of the file.

### Set up Capistrano

Add the following to Discourse's `Gemfile`:

{% gist davidcelis/6f2b367bf12509a6c9c4 Gemfile %}

Create a `Capfile` in Discourse's root directory:

{% gist davidcelis/6f2b367bf12509a6c9c4 Capfile %}

Create your deployment recipe file at `config/deploy.rb`. Here's what mine looks like:

{% gist davidcelis/6f2b367bf12509a6c9c4 deploy.rb %}

These should be all of the necessary Capistrano recipes you need to run your first deployment. Let's do that now!

## Deploy Discourse

Okay, you've got your server set up and Discourse configured... Let's do this!

{% gist davidcelis/6f2b367bf12509a6c9c4 deploy.sh %}

## Configure Discourse

Congratulations! You should now have Discourse running on your VPS. Now that your forums are up and running, you'll want to follow the [Quick Start Guide][quick-start] that the Discourse team has written up.

## Keeping Discourse up-to-date

You'll, of course, want to keep your copy of Discourse up-to-date with the main repository. To do so, `cd` into your local copy and set up an upstream remote:

{% gist davidcelis/6f2b367bf12509a6c9c4 upstream.sh %}

And there you go. Whenever you want to update, just fetch upstream, merge it into master, push, and redeploy.

### Anything here wrong?

Please let me know if the above steps didn't work for you. It's possible that I accidentally left a step out of my process or that the process has changed and I don't know about it. Reply to [my thread on meta.discourse.org][meta-discourse-thread] where I've posted this guide, or shoot me an email using the link at the top.

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
