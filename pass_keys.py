import kitty.conf.utils as ku
import kitty.key_encoding as ke
from kitty import keys
import re


def main():
    pass

def actions(extended):
    yield keys.defines.GLFW_PRESS
    if extended:
        yield keys.defines.GLFW_RELEASE

def convert_mods(mods):
    """
    converts key_encoding.py style mods to glfw style mods as required by key_to_bytes
    """
    glfw_mods = 0
    if mods & ke.SHIFT:
        glfw_mods |= keys.defines.GLFW_MOD_SHIFT
    if mods & ke.ALT:
        glfw_mods |= keys.defines.GLFW_MOD_ALT
    if mods & ke.CTRL:
        glfw_mods |= keys.defines.GLFW_MOD_CONTROL
    if mods & ke.SUPER:
        glfw_mods |= keys.defines.GLFW_MOD_SUPER
    return glfw_mods


def handle_result(args, result, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id)
    tab = boss.active_tab

    if w is None:
        return

    if len(args) > 4:
        if not re.search(args[4], w.title):
            boss.active_tab.neighboring_window(args[2])
            return
    else:
        # check the first word of the first foreground process
        foreground_process = w.child.foreground_processes[0]['cmdline'][0]
        if not re.search("n?vim", foreground_process, re.I):
            boss.active_tab.neighboring_window(args[2])
            return

    mods, key, is_text = ku.parse_kittens_shortcut(args[3])

    extended = w.screen.extended_keyboard

    for action in actions(extended):
        sequence = (
            ('\x1b_{}\x1b\\' if extended else '{}')
            .format(
                keys.key_to_bytes(
                    getattr(keys.defines, 'GLFW_KEY_{}'.format(key.upper())),
                    w.screen.cursor_key_mode, extended, convert_mods(mods), action)
                .decode('ascii')))
        print(repr(sequence))
        w.write_to_child(sequence)


handle_result.no_ui = True
