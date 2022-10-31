---
layout: post
title: "Easily Publish Your Site to S3 and CloudFront"
date: 2015-12-13 17:01
categories: [programming, aws, s3, cloudfront, static]
---

Until recently, my site was hosted on GitHub Pages. It's a static site built using Jekyll so, because Pages is free, supports custom domains, and automatically builds Jekyll sites for you, it made sense. Unfortunately, ease often comes with caveats. In the case of Pages, there were three main caveats for me:

### No SSL on custom domains

In the age of [HTTPS Everywhere](https://www.eff.org/https-Everywhere), it's a major drawback not to be able to support SSL on your website. Even Google has said that [HTTPS sites will get preferential placement in search results](http://www.newsledge.com/seo-google-encryption-let-rush-https-begin-8485). I know that my site is just a static application with no forms or POSTs, but even having an SSL certificate that shows this domain is really owned by me is nice for verification purposes.

### No custom caching headers

Now, to be fair, GitHub _does_ use Fastly as their CDN. However, the speed benefits are apparently somewhat lost if you use a naked subdomain instead of something like "www". Additionally, they set their max-age value for assets to only 600 seconds. The font files on my website will never change, and the CSS (and even existing pages) very rarely change. I wanted to be able to tell web browsers to fetch these files from the browser cache for up to one year and prevent retrieving them over the network.

### Jekyll is forced into safe mode

GitHub runs Jekyll in safe mode by default, for obvious reasons. This means that you are unable to use [Jekyll Plugins](http://jekyllrb.com/docs/plugins/) on GitHub Pages. This wasn't actually a _huge_ deal for me, as I was able to get by somewhat easily without introducing custom plugins. But there's some nice stuff out there in the Jekll ecosystem.

## Onward to AWS!

With these issues in mind, I decided to try moving my site to AWS. I knew that this would involve hosting my built site in an Amazon S3 bucket and, in order to have effective caching and serve my site over a CDN, I'd need to put a CloudFront distribution in front of it. I didn't think this process would be as tricky to get right, but it ended up being a bit arduous. However, by the end, I was left with mostly what I wanted:

* My site now runs on SSL at [https://davidcel.is/](https://davidcel.is/)
* If a user visits my site on HTTP, they are redirected to HTTPS.
* If a user visits my site with a www subdomain, they are redirected to a naked subdomain.
* CSS files are versioned with a query parameter (I wanted fingerprints but couldn't get existing third party plugins to work for my purposes).
* After the first visit, browser caching has most pages typically loading and fully rendered in less than 100ms (blog posts with embedded media are still a bit slower, but what are you gonna do).

Want the same sort of setup for your own site? Here's how I did it:

### s3_website

[s3_website](https://github.com/laurilehmijoki/s3_website) is a Ruby gem that facilitates the publishing of a static site to S3 and CloudFront. It supports Jekyll out of the box and automatically detects a site built and placed in the `_site` directory of a project. It also has a fairly sane default configuration and has decent usage documentation. I thought that my search was over when I found this project, but I hit a few snags and had to do too much reading in CloudFront's documentation to let anybody else do the same. Anyway, start by installing s3_website and generating a configuration in your project:

{% gist davidcelis/525f97ba92181b9f6734 %}

This will give you a YAML configuration file in the root of your project. Read through it to see various configuration options you might want to set, but I'll go ahead and give you my final configuration in a bit. In the meantime, head over to the [AWS Console](http://aws.amazon.com). You'll need to generate an access key and secret if you haven't already. Under the "Security & Identity" group of apps, enter the "Identity & Access Management" (IAM) app. Click "Users" and create one. Then, click through to your new user and attach a policy. The one you'll want is called "AdministratorAccess". Or you can just give it access to S3 and CloudFront. Finally, visit your new user's Security Credentials tab and create an access key. This is the only time that the access key's secret will be shown, so make sure to grab them both before you leave.

Alright. Once you've gotten your credentials and read through the default configuration, you can take a look at what I've got:

{% gist davidcelis/0d22be6dd74879f04b3a %}

I placed any sensitive configuration options in environment variables so that anybody viewing my site's [repository on GitHub](https://github.com/davidcelis/davidcel.is/) could see what values I have set. `s3_id` and `s3_secret` are the Access Key/Secret that you created for your new AWS user. `s3_bucket` and `s3_endpoint` configure your bucket's name and which of Amazon's data centers it will be in (there's a [list of these endpoints](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region) available in Amazon's documentation). The bucket doesn't have to exist yet; `s3_website` will create it for you! In fact, you can leave `cloudfront_distribution_id` out too as `s3_website` will also create your CloudFront distribution for you. In the meantime, let's walk through the rest of these values to get a sense of what'll be going on.

This `cloudfront_invalidate_root` option is necessary if you're using pretty URLs that don't involve an `index.html` file (e.g. https://example.com/about/ instead of https://example.com/about/index.html). This makes sure that when the, say, `/about/index.html` file changes, CloudFront invalidates the cache for the resource located at `/about/`. Handy!

The `cloudfront_distribution_config` section contains settings for the CloudFront distribution and its behaviors. I've set the minimum caching TTL to one day, and stated that HTTP requests should be redirected to HTTPS. Then, I've provided one CNAME alias: my domain, davidcel.is.

Then I tell S3 that my site's root document (located at https://davidcel.is/) is the top-level `index.html` file, and that any errors experienced should render the top-level `404.html` file.

Finally, I've set some additional caching rules. CSS, fonts, and images will all get a max-age of a whole whopping year, so browsers are instructed to retrieve them from their local cache until that age has expired. This is great for font files and images which should never change. CSS changes do occur, so I end up versioning those files using query parameters (more on that later). Last but not least, I tell CloudFront to deliver my HTML and CSS files gzipped. Normally you'd include `.js` in that list, but the only JavaScript I use is for analytics.

Once you've got the configuration you want, you can run `s3_website cfg apply`. This command will use your AWS credentials on Amazon's API to create your S3 bucket and CloudFront distribution with the configuration we just talked about.

Finally, you can build and publish your site:

{% gist davidcelis/0c16a9c3e39f972340d2 %}

Any time you update your website and re-build it, just use `s3_website push` to update it in CloudFront. The command will calculate the diff of your new site with the old site and update only the files that need to be invalidated. If you want to invalidate everything, you can add the `--force` option.

### HTTPS

In order to serve HTTPS from your own domain name, you'll need to get an SSL certificate. I won't detail the process of obtaining one, but I will recommend two sources:

1. [StartSSL](http://startssl.com) offers free SSL certificates that last for a year. Sign-up is a bit time consuming and involves creating and saving an SSL certificate just to identify you and authenticate on their website, but I'd rather go through their process than pay exorbitantly for a certificate. Their certificates require a subdomain, but will also work on a naked domain. I'd suggest getting a certificate with the "www" subdomain which would, for example, work for both "www.example.com" and "example.com".
2. [Let's Encrypt](http://letsencrypt.org) has been making the rounds lately, promising free, automated SSL certificates. They'll even be issuing wildcard certificates! The caveat here is that it's still a beta product, and certificates currently only last for 90 days.

Once you have your SSL certificate, you have to upload it to Amazon. I spent ages trying to figure out how to do this in their web console, but it's much easier to do it from the command line. You'll need a few files, the names of which I'll assume:

* Your newly generated SSL certificate (`ssl.crt`)
* The SSL certificate's private key (`ssl.key`)
* Your provider's Certificate Authority (CA) bundle (`ca-bundle.pem`)

When you've got these files ready, install the AWS Command Line Interface and go to town (replacing `example.com` with your domain):

{% gist davidcelis/55b7811f25633b4a3824 %}

Once the certificate is uploaded, head back to the [AWS Console](http://aws.amazon.com) and navigate to the CloudFront app. Click into the distribution that was created for your site,  click "Edit", and select "Custom SSL Certificate (stored in AWS IAM)". Make sure the certificate in the dropdown is selected, and save.

### Hook up your DNS

The last step is pointing your domain's DNS at your newly created CloudFront distribution. In the console, grab your distribution's "Domain Name" value. It should look something like "a2ebi9s43z9v9o.cloudfront.net". You'll want the following two records, replacing `example.com` with your own domain and `a2ebi9s43z9v9o.cloudfront.net` with your actual CloudFront distribution's domain name:

* An ALIAS record for `example.com` pointing to `a2ebi9s43z9v9o.cloudfront.net`. If your DNS provider doesn't support ALIAS records, your only choice is a CNAME. Unfortunately, CNAMEs can't be used to point naked domains at another domain, so you'll need something like `www.example.com` or `blog.example.com`.
* A URL record for `www.example.com` pointing to `example.com`. This is only if you want to redirect a `www` subdomain to a naked domain. If your DNS provider doesn't have this record type, the only solution I can think of is routing `www.example.com` to a lightweight VPS running nginx that just redirects to `example.com`.

There's also a big caveat with that URL record. These records can't redirect over SSL, so if somebody were to visit `https://www.example.com`, it'll hang in the web browser. I personally want the redirection and, because my site has never been on SSL before, I doubt there are any links out there in the wild to the https://www version of my website. I'm willing to risk it, but you might not be. I also tried to set up a second origin in CloudFront for the `www` subdomain that would read out of a second S3 bucket named `www.davidcel.is` (merely a mirror for my original bucket) but I couldn't get it to quite work right. If anybody else has, please email me with steps so I can put them here! Otherwise, I'd recommend the VPS solution if you don't mind paying or if you already have a box. That Nginx configuration could be as simple as this:

{% gist davidcelis/19be3a99c911dff1768b %}

### Wait a bit...

Once CloudFront finishes deploying your cached distribution and DNS kicks in, you should have a nice, fast site running low-cost on AWS. Rejoice!
