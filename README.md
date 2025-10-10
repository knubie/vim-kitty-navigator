# Vim Kitty Navigator

This plugin is a port of [Chris Toomey's vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) plugin. When combined with a set of kitty
key bindings and kittens, the plugin will allow you to navigate seamlessly between vim and kitty splits using a consistent set of hotkeys.

> [!IMPORTANT]
> This plugin requires kitty v0.30.0 or higher.

## Usage

This plugin provides the following mappings which allow you to move between
Vim panes and kitty splits seamlessly.

- `<ctrl-h>` → Left
- `<ctrl-j>` → Down
- `<ctrl-k>` → Up
- `<ctrl-l>` → Right

If you want to use alternate key mappings, see the [configuration section below](https://github.com/knubie/vim-kitty-navigator#custom-key-bindings).

## Installation

### Neo/Vim

You can install `vim-kitty-navigator` using your favorite plugins manager:

Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'knubie/vim-kitty-navigator'
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "knubie/vim-kitty-navigator"
}
```

### Kitty

To configure the kitty side of this customization there are three parts:

#### 1. Add `get_layout.py` kitten

Move `get_layout.py` kitten to the `~/.config/kitty/` directory.

This can be done manually or with a post-update hook in your package manager:

Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'knubie/vim-kitty-navigator', {'do': 'sh -c "[ -d "~/.config/kitty/" ] && cp ./*.py ~/.config/kitty/"'}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    'knubie/vim-kitty-navigator',
    build = 'sh -c "[ -d "~/.config/kitty/" ] && cp ./*.py ~/.config/kitty/"',
}
```
> [!NOTE]
> This plugin uses the remote control socket feature of kitty and thus supports using 
> [kitty over ssh](https://sw.kovidgoyal.net/kitty/kittens/ssh/) (given Neo/Vim
> are installed on your remote machine).
> This means that the remote machine may only have the standalone `kitten` 
> binary installed and therefore not have a `~/.config/kitty` directory.
> Therefore, we only want to copy the `get_layout.py` kitten if such a directory
> exists (i.e. on your local machine where the full kitty software is running).
> If you do not have Neo/Vim installed on your local machine and you have not
> installed this plugin locally using the above method, you will have to manually 
> add `get_layout.py` to your `~/.config/kitty` directory.

> [!NOTE]
> We suggest copying by regex for python files (`./*.py`) for 
> legacy reasons and to support future kittens, but you are 
> welcome to just copy `./get_layout.py` instead

The `get_layout.py` kitten is used to check whether the current kitty tab is in `stack` layout mode so that it can prevent accidentally navigating to a hidden stack window.

#### 2. Configure Neo/Vim to modify it's modify the window's environment variables on enter

Kitty needs to be able to tell if the current window is running Neo/Vim or not in order 
to decide whether to focus a neighboring kitty window or pass the key to Neo/Vim.

To do so, we must tell Neo/Vim to set an environment variable upon enter and unset it 
upon exit, then in step 3, we'll unmap the keys from kitty if this variable is set so 
the plugin can handle the vim navigation.

See the kitty [key-mapping documentation](https://sw.kovidgoyal.net/kitty/mapping/#conditional-mappings-depending-on-the-state-of-the-focused-window) for details.

For Vim:
```vim
let &t_ti = &t_ti . "\033]1337;SetUserVar=in_vim=MQo\007"
let &t_te = &t_te . "\033]1337;SetUserVar=in_vim\007"
```

For Neovim:
```lua
vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume' }, {
  group = vim.api.nvim_create_augroup('KittySetVarVimEnter', { clear = true }),
  callback = function()
    io.stdout:write '\x1b]1337;SetUserVar=in_vim=MQo\007'
  end,
})

vim.api.nvim_create_autocmd({ 'VimLeave', 'VimSuspend' }, {
  group = vim.api.nvim_create_augroup('KittyUnsetVarVimLeave', { clear = true }),
  callback = function()
    io.stdout:write '\x1b]1337;SetUserVar=in_vim\007'
  end,
})
```
or if you're using [lazy.nvim](https://github.com/folke/lazy.nvim), you can add an `init` function to your plugin spec:
```lua
{
  'knubie/vim-kitty-navigator',
  build = 'sh -c "[ -d "~/.config/kitty/" ] && cp ./*.py ~/.config/kitty/"',
  init = function()
    vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume' }, {
      group = vim.api.nvim_create_augroup('KittySetVarVimEnter', { clear = true }),
      callback = function()
        io.stdout:write '\x1b]1337;SetUserVar=in_vim=MQo\007'
      end,
    })

    vim.api.nvim_create_autocmd({ 'VimLeave', 'VimSuspend' }, {
      group = vim.api.nvim_create_augroup('KittyUnsetVarVimLeave', { clear = true }),
      callback = function()
        io.stdout:write '\x1b]1337;SetUserVar=in_vim\007'
      end,
    })
  end,
}
```

#### 3. Create the conditional key mappings in kitty.con

Add the following to your `~/.config/kitty/kitty.conf` file:

```conf
map ctrl+h neighboring_window left
map ctrl+j neighboring_window down
map ctrl+k neighboring_window up
map ctrl+l neighboring_window right
map --when-focus-on var:in_vim ctrl+h
map --when-focus-on var:in_vim ctrl+j
map --when-focus-on var:in_vim ctrl+k
map --when-focus-on var:in_vim ctrl+l
```

This conditionally unmaps the window switching key-presses from kitty if the 
current window is running Neo/Vim.

#### 4. Make kitty listen to control messages

Start kitty with the `listen-on` option so that vim can send commands to it.

```conf
# For linux only:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty

# Other unix systems:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:/tmp/mykitty
```

or if you don't want to start kitty with above mentioned command,
simply add below configuration in your `kitty.conf` file.

```conf
# For linux only:
allow_remote_control yes
listen_on unix:@mykitty

# Other unix systems:
allow_remote_control yes
listen_on unix:/tmp/mykitty
```

You can also set `allow_remote_control` to `socket` or `socket-only` for more security

> [!TIP]
> After updating kitty.conf, close kitty completely and restart. Kitty does not support enabling `allow_remote_control` on configuration reload.

You can provide a [kitty remote control password](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.remote_control_password)
by setting the variable `g:kitty_navigator_password` to the desired kitty
password, e.g.:

```vim
let g:kitty_navigator_password = "my_vim_password"
```

> [!TIP]
> Mac users can learn more about command line options in kitty, from [this](https://sw.kovidgoyal.net/kitty/faq/#how-do-i-specify-command-line-options-for-kitty-on-macos) link.

## Configuration

### Custom Key Bindings

If you don't want the plugin to create any mappings, you can use the five
provided functions to define your own custom maps. You will need to define
custom mappings in your Neo/Vim configuration as well as update the 
bindings in kitty to match.

For Vim:

```vim
let g:kitty_navigator_no_mappings = 1

nnoremap <silent> {Left-Mapping} :KittyNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :KittyNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :KittyNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :KittyNavigateRight<cr>
```

For Neovim:
```lua
vim.g.kitty_navigator_no_mappings = 1

vim.keymap.set('n', '{Left-Mapping}', ':KittyNavigateLeft<CR>', { silent = true, desc = 'Kitty Navigate Left' },
vim.keymap.set('n', '{Down-Mapping}', ':KittyNavigateDown<CR>', { silent = true, desc = 'Kitty Navigate Down' },
vim.keymap.set('n', '{Up-Mapping}', ':KittyNavigateUp<CR>', { silent = true, desc = 'Kitty Navigate Up' },
vim.keymap.set('n', '{Right-Mapping}', ':KittyNavigateRight<CR>', { silent = true, desc = 'Kitty Navigate Right' },
```
or if you're using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  'knubie/vim-kitty-navigator',
  build = 'sh -c "[ -d "~/.config/kitty/" ] && cp ./*.py ~/.config/kitty/"',
  init = function()
    vim.g.kitty_navigator_no_mappings = 1
    -- rest of you init function (shown above)
  end,
  keys = {
    { '{Left-Mapping}', ':KittyNavigateLeft<CR>', desc = 'Kitty Navigate Left', silent = true },
    { '{Down-Mapping}', ':KittyNavigateDown<CR>', desc = 'Kitty Navigate Down', silent = true },
    { '{Up-Mapping}', ':KittyNavigateUp<CR>', desc = 'Kitty Navigate Up', silent = true },
    { '{Right-Mapping}', ':KittyNavigateRight<CR>', desc = 'Kitty Navigate Right', silent = true },
  },
}
```

> [!NOTE]
> Replace `{*-Mapping}` in the above code with your desired mapping 
> (e.g. the mapping for 'ALT+h' => 'Left' would be created with 
> `nnoremap <silent> <A-h> :KittyNavigateLeft<cr>` in Vim).
> You will also have to replace the mappings in your `kitty.conf` 
> (e.g. `map alt+h neighboring_window left` and 
> `map --when-focus-on var:in_vim ctrl+h`)

### Navigating In Stacked Layout

By default `vim-kitty-navigator` prevents navigating to "hidden" windows while in
stacked layout. This is to prevent accidentally switching to a window that is
"hidden" behind the current window. The default behavior can be overridden by
setting the `g:kitty_navigator_enable_stack_layout` variable to `1`:

For Vim:
```vim
let g:kitty_navigator_enable_stack_layout = 1
```

For Neovim:
```lua
vim.g.kitty_navigator_enable_stack_layout = 1
```

> [!WARNING]
> ## Breaking changes
>
> The latest version of this plugin requires kitty [v0.30.0](https://sw.kovidgoyal.net/kitty/changelog/) or higher. This version introduced a new option to `kitty @ focus-window` that allows focusing a neighboring window.

## Troubleshooting

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
