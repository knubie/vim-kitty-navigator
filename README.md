Vim Kitty Navigator
==================

This plugin is a port of [Chris Toomey's vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) plugin. When combined with a set of kitty
key bindings and kittens, the plugin will allow you to navigate seamlessly between vim and kitty splits using a consistent set of hotkeys.

**NOTE**: This requires kitty v0.13.1 or higher.

Usage
-----

This plugin provides the following mappings which allow you to move between
Vim panes and kitty splits seamlessly.

- `<ctrl-h>` => Left
- `<ctrl-j>` => Down
- `<ctrl-k>` => Up
- `<ctrl-l>` => Right

If you want to use alternate key mappings, see the [configuration section below](https://github.com/knubie/vim-kitty-navigator#custom-key-bindings).

Installation
------------

### Vim

If you don't have a preferred installation method, I recommend using [vim-plug](https://github.com/junegunn/vim-plug).
Assuming you have `vim-plug` installed and configured, the following steps will
install the plugin:

Add the following line to your `~/.vimrc` file

``` vim
Plug 'knubie/vim-kitty-navigator'
```

Then run

```
:PlugInstall
```

### kitty

To configure the kitty side of this customization there are three parts:

#### Add `pass_keys.py` and `neighboring_window.py` kittens

Move both `pass_keys.py` and `neighboring_window.py` kittens to the `~/.config/kitty/`. It can be done manually or with the `vim-plug` post-update hook
``` vim
Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'}
```

The `pass_keys.py` kitten is used to intercept keybindings defined in your kitty conf and "pass" them through to vim when it is focused. The `neighboring_window.py` kitten is used to send the `neighboring_window` command (e.g. `kitten @ neighboring_window.py right`) from vim when you've reached the last pane and are ready to switch to a non-vim kitty window.

#### Add this snippet to kitty.conf

Add the following to your `~/.config/kitty/kitty.conf` file:

```conf
map ctrl+j kitten pass_keys.py neighboring_window bottom ctrl+j
map ctrl+k kitten pass_keys.py neighboring_window top    ctrl+k
map ctrl+h kitten pass_keys.py neighboring_window left   ctrl+h
map ctrl+l kitten pass_keys.py neighboring_window right  ctrl+l
```

By default `vim-kitty-navigator` uses the name of the current foreground process to detect when it is in a (neo)vim session or not. If that doesn't work, (or if you want to support applications other than vim) you can supply a fourth optional argument to the `pass_keys.py` call in your `kitty.conf` file to match the process name. 

```conf
map ctrl+j kitten pass_keys.py neighboring_window bottom ctrl+j "^.* - nvim$"
map ctrl+k kitten pass_keys.py neighboring_window top    ctrl+k "^.* - nvim$"
map ctrl+h kitten pass_keys.py neighboring_window left   ctrl+h "^.* - nvim$"
map ctrl+l kitten pass_keys.py neighboring_window right  ctrl+l "^.* - nvim$"
```

#### Make kitty listen to control messages

Start kitty with the `listen-on` option so that vim can send commands to it.

```
# For linux only:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty

# Other unix systems:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:/tmp/mykitty
```

or if you don't want to start kitty with above mentioned command,
simply add below configuration in your `kitty.conf` file.

NOTE: Close kitty completely and restart, then only it works as kitty doesnt support to `allow_remote_control` on configuration reload.

```
# For linux only:
allow_remote_control yes
listen_on unix:@mykitty

# Other unix systems:
allow_remote_control yes
listen_on unix:/tmp/mykitty
```

You can provide a [kitty remote control password](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.remote_control_password)
by setting the variable `g:kitty_navigator_password` to the desired kitty
password, e.g.:
``` vim
let g:kitty_navigator_password = "my_vim_password"
```

Also, Mac users can learn more about command line options in kitty, from [this](https://sw.kovidgoyal.net/kitty/faq/#how-do-i-specify-command-line-options-for-kitty-on-macos) link.

Configuration
-------------

### Custom Key Bindings

If you don't want the plugin to create any mappings, you can use the five
provided functions to define your own custom maps. You will need to define
custom mappings in your `~/.vimrc` as well as update the bindings in kitty to
match.

#### Vim

Add the following to your `~/.vimrc` to define your custom maps:

``` vim
let g:kitty_navigator_no_mappings = 1

nnoremap <silent> {Left-Mapping} :KittyNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :KittyNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :KittyNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :KittyNavigateRight<cr>
```

*Note* Each instance of `{Left-Mapping}` or `{Down-Mapping}` must be replaced
in the above code with the desired mapping. Ie, the mapping for `<ctrl-h>` =>
Left would be created with `nnoremap <silent> <c-h> :KittyNavigateLeft<cr>`.

Troubleshooting
---------------

If you are not able to navigate around vim, try the following:

1. Make sure you are using the latest version of Kitty.
1. Make sure you are using the latest commit of `vim-kitty-navigator`
1. Add a print statement in `pass_keys.py` between line 7 and 8 like this:
   ```python
   def is_window_vim(window, vim_id):
    fp = window.child.foreground_processes
    print(fp)
    return any(re.search(vim_id, p['cmdline'][0], re.I) for p in fp)
    ```
1. Then run kitty in a debug mode:
   ```
   kitty --debug-keyboard
   ```
1. when the new window is opened, open up vim and some splits and try navigating around. When navigating your vim splits you should see some output similar to this:
   ```
   KeyPress matched action: kitten
   [{'pid': 97247, 'cmdline': ['nvim', '.'], 'cwd': '/Users/matt/.config/kitty'}]
   ```
The `'cmdline': ['nvim', '.']` part will tell us the title of the vim window that we're using to match against in the script. Double check the regex in `pass_keys.py`, or the regex you passed in to `kitty.confg` with that title to make sure they match.
