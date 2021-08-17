import kitty.conf.utils as ku
import kitty.key_encoding as ke
from kittens.tui.handler import result_handler
import kitty.fast_data_types as fdt
import re

func_with_args, args_funcs = ku.key_func()

def main():
    pass

def actions(extended):
    yield fdt.GLFW_PRESS
    if extended:
        yield fdt.GLFW_RELEASE

def convert_mods(mods):
    """
    converts key_encoding.py style mods to glfw style mods as required by key_to_bytes
    """
    glfw_mods = 0
    if mods & ke.SHIFT:
        glfw_mods |= fdt.GLFW_MOD_SHIFT
    if mods & ke.ALT:
        glfw_mods |= fdt.GLFW_MOD_ALT
    if mods & ke.CTRL:
        glfw_mods |= fdt.GLFW_MOD_CONTROL
    if mods & ke.SUPER:
        glfw_mods |= fdt.GLFW_MOD_SUPER
    return glfw_mods


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id)
    tab = boss.active_tab
    # The direciton to move to, e.g. top, right, bottom, left
    direction = args[2]
    # a key mapping, e.g. "ctrl+h"
    key_mapping = args[3] 
    # The regular expresion to use to match against the process name.
    # This can be changes by passing a fourth argument to pass_keys.py
    # in your kitty.conf file.
    process_name = args[4] if len(args) > 4 else "n?vim"

    if w is None:
        return

    else:
        fp = w.child.foreground_processes
        # check the first word of the each foreground process
        if not any(re.search(process_name, p['cmdline'][0], re.I) for p in fp):
            boss.active_tab.neighboring_window(direction)
            return

    # mods, key, is_text = ku.parse_kittens_shortcut(key_mapping)
    mods, key = ke.parse_shortcut(key_mapping)

    extended = w.screen.current_key_encoding_flags() & 0b1000

    for action in actions(extended):
        sequence = (
            ('\x1b_{}\x1b\\' if extended else '{}')
            .format(
                fdt.encode_key_for_tty(
                    getattr(fdt, 'GLFW_FKEY_{}'.format(key.upper())),
                    w.screen.cursor_key_mode, extended, convert_mods(mods), action)))
        w.write_to_child(sequence)
