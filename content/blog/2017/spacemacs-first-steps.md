---
title: "Spacemacs - First Steps"
date: 2017-02-06T20:19:45Z
draft: false
tags: [emacs, spacemacs]
---

# Moving to Spacemacs

I recently declared, if not
quite [.emacs bankruptcy](https://www.emacswiki.org/emacs/DotEmacsBankruptcy)
, then at least Chapter 11 status. After a long time keeping my .emacs as a single
file, I refactored it into a set of self contained lisp files of the form:

```lisp
(require 'other-peoples-packages)
...my config...
(provide 'my-package)
```

Then I just ensured the director with all these files was on my `load-path` and simply
`require`d my own little packages.

This worked very nicely, and seemed to have the side effect of speeding up Emacs
startup. However, I still had quite a way to go to configure a proper
development environment, especially code completion, so I decided to take a look
at [Spacemacs](https://github.com/syl20bnr/spacemacs) since it claims to have
such stuff "preconfigured, out of the box". Interestingly, it seemed to be using
many of the packages that I was already using in my own configuration, so I
hoped to be able to eliminate some of my own code.

# Installation

To avoid clobbering my existing Emacs configuration I created a new user in
Linux Mint and simply followed the instructions at the Github repo. The first
time that Spacemacs starts you are asked what editing style you prefer - Vim or
Emacs - and it downloads a lot of packages from the Emacs package archives.

I had previously been put off from Spacemacs by the stress that the
documentation places on Evil mode, however I am pleased to report that if you
choose Emacs style editing then, as far as I can tell, it works just like
standard Emacs does - at least if you are used
to [Helm](https://github.com/emacs-helm/helm) and [Hydra](https://github.com/abo-abo/hydra).

# Porting my .emacs configuration

Once I was up and running the process of porting my existing .emacs began. This
was a frustrating process to begin with, it took me a few days to grok what was
really happening. It has to be said that
the [documentation](http://spacemacs.org/doc/DOCUMENTATION) is excellent, but
there is a lot to take in at one sitting.

As an experienced Emacs user with a significant amount of configuration to
port, [the advice](http://spacemacs.org/doc/DOCUMENTATION#dotfile-configuration)
to put most of your customization in the `dotspacemacs/user-config` function
doesn't feel like a good move. It could end up being huge and would in fact be a
backward step from my nicely modularized configuration.

The route I quickly decided on was to write my
own [Spacemacs layer](http://spacemacs.org/doc/LAYERS.html#introduction), which
I called simply "pd". Layers come with a pre-defined set of files which are
loaded in a specific order:

* layers.el (declare "extra" layers)
* packages.el (where you configure the packages you are using)
* funcs.el (where you declare functions, obviously)
* config.el (for your layer's variables)
* keybindings.el (general keybindings, not package specific)

`funcs.el` and `keybindings.el` were pretty easy to port. Writing `packages.el`
was a bit more challenging, one issue that I ran into was that I wanted to use a
function that I had declared in `funcs.el` as part of my initialization but it
wasn't loaded by then. It would make more sense to me to load `funcs.el` before
`packages.el`, but when you start to use a framework like Spacemacs you have to
work within the constraints it sets you. My `packages.el` has actually ended up
pretty small, it just brings in a few little custom packages that I like to use.

Incidentally, the trick to reusing packages that are not on ELPA - whether they
are yours or anyone else's - is just to create a folder under your layer called
"local", for example, under my "pd" layer I have the `buffer-move` package
download from the Emacs wiki, and a package of my own containing hydras:

    pd\local\buffer-move\buffer-move.el
    pd\local\pd-hydra\pd-hydra.el

I can then initialize them simply within `packages.el`:

```lisp
(defun pd/init-pd-hydra ()
  (use-package pd-hydra))
```

I still have quite a number of settings that are not related to any package in
particular, and these have all ended up in the `dotspacemacs/user-config`
function. However, since Spacemacs seems so well configured out of the box, it's
a much smaller list than I used to have in my own .emacs configuration.

# Replacing hydras

Spacemacs uses [Hydra](https://github.com/abo-abo/hydra) to create what it calls
"Transient States". One that caught my attention was the "Window Manipulation
Transient State". which is bound to `SPC w .` by default. I had previously
developed my own very similar hydra, though with non-VIM keybindings and some
extra functions, such as the ability to open `helm-mini`, bring up dired, save
the current buffer etc.

I couldn't figure out a way of augmenting a built-in hydra - not really
surprising because the design of them is so intricate, especially if they use a
docstring. So I just copied the built-in one, pasted it into my `keybindings.el`
and hacked it until I had it just how I wanted it. Then I bound it to the
standard keybinding:

```lisp
(spacemacs|define-transient-state pd-window-manipulation
  :title "Phil's Window Manipulation Transient State."
  :doc (concat "M-arrow = select, M-S-arrow = move, S-arrow = resize. 0-9 = select window N.

Split^^              Buffers^^      Windows^^          Files^^         Other
─────^^───────────── ───────^^───── ───────^^───────── ─────^^──────── ─────^^──────────────────
[___] vertical       [_n_] next     [_c_] close        [_b_] helm mini [_u_] restore prev layout
[_V_] vert & follow  [_p_] previous [_o_] close others [_f_] helm find [_U_] restore next layout
[_|_] horizontal     [_k_] kill     [_r_] rotate fwd   [_d_] dired     [_F_] go to other frame
[_H_] horiz & follow [_s_] save     [_R_] rotate bwd   [_t_] terminal  [_g_] golden-ratio-mode")

...


(spacemacs/set-leader-keys "w." 'spacemacs/pd-window-manipulation-transient-state/body)
```

The full thing can be [found here](https://github.com/PhilipDaniels/pd), but be
warned, it is still evolving!

# Theme customization

One of the first things I wanted to change in Spacemacs was the default theme.
Just my luck that my longstanding favourite theme
[Sellout's Solarized](https://github.com/sellout/emacs-color-theme-solarized)
uses a non-standard loading mechanism and was a bit tricky to configure.
I [have another post]({{< ref "spacemacs-solarized.md" >}})
detailing how to do it.

# Conclusion

After hacking on it on and off for about a week I now have a Spacemacs
configuration that contains everything I deemed really important from my own
config, and in fact the amount of configuration code I need seems to have
diminished quite significantly. I was really surprised how small my
`packages.el` file had become when I reviewed it for this post.

Sometime in the not too distant future I expect to be moving over to using
Spacemacs rather than my old config. Just need to perfect my hyper key on Linux
first...I also want to take the opportunity to produce a set of keybindings that
are much more in line with the Windows and Visual Studio defaults.

If you are a new Emacs user or don't have much invested in your `.emacs`, I
would say it is a no-brainer - you should definitely start with Spacemacs rather
than Emacs. It is just a much better out-of-the-box experience.

If you are an intermediate or advanced user with a lot of configuration
investment, then I would still consider the switch worthwhile, but it will
probably take a little longer to get back to status quo. It would be nice if the
Spacemacs documentation had more guidance for users in this situation.
