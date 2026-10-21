---
layout: post
title: "Connecting to GitHub with SSH in VS Code"
date:   2018-01-31 03:00:00
categories:
- Git
tags:
- git
- vs code
ko_sha: eb5dbd6a3a9e4870962d9afe41c94b774ed8406b
---

Pushing to GitHub from VS Code without SSH meant typing my ID and password every time, which became annoying...

So I will create an SSH key, register it on GitHub, and change the remote address so that authentication is easier!

First, let's create an SSH key.

{% highlight bash %}
# Check whether you already have a key...
$ cd ~/.ssh

# If not, create one!
$ ssh-keygen  -C "your github email"
{% endhighlight %}

I created the key without a passphrase, so I just mashed Enter...
(Of course, this may be insecure...!)

When it is done, 2 files, id_rsa and id_rsa.pub, will have been created in .ssh.
Register the public key (id_rsa.pub) on GitHub and keep the private key (id_rsa) safe.

After logging in to GitHub, click SSH and GPG keys in settings, then click New SSH key!

Choose any title you like and paste the public key (id_rsa.pub) into the key field.

After saving, let's test SSH locally.

{% highlight bash %}
#Check whether the ssh agent is running
$ eval "$(ssh-agent -s)"

#Register the private key with the agent
$ ssh-add ~/.ssh/id_rsa

#Test the GitHub ssh connection
$ ssh -T git@github.com
{% endhighlight %}

The first time, you will probably see a message like the one below.

{% highlight bash %}
The authenticity of host 'github.com (IP ADDRESS)' can't be established.
RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8.
Are you sure you want to continue connecting (yes/no)?
{% endhighlight %}

Type yes and test once more, and it succeeds!

Next, change the git remote of your project.

{% highlight bash %}
#Check the remote address
$ git remote -v

#Change the remote address
$ git remote set-url origin your_ssh_url
{% endhighlight %}

For the SSH address, click the use ssh button when cloning your project, and the address appears.

{% highlight bash %}
#Check the changed remote address
$ git remote -v
{% endhighlight %}

After that, just check the changed address.

Authenticating with ID/password on every push over HTTPS was annoying, but after switching to SSH it is convenient.

Skipping the passphrase is insecure, so be careful with how you manage the private key!
