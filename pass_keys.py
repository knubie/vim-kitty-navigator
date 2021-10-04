from kittens.tui.handler import result_handler
from kitty.key_encoding import ( KeyEvent, encode_key_event, parse_shortcut )
import re


def is_window_vim(window, vim_id):
    fp = window.child.foreground_processes
    return any(re.search(vim_id, p['cmdline'][0], re.I) for p in fp)


def encode_key_mapping(key_mapping):
    mods, key = parse_shortcut(key_mapping)
    ev = KeyEvent(mods=mods, key=key, shift=bool(mods & 1), alt=bool(mods & 2), ctrl=bool(mods & 4),
            super=bool(mods & 8), hyper=bool(mods & 16), meta=bool(mods & 32))
    return encode_key_event(ev)


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    direction = args[2]
    key_mapping = args[3]
    vim_id = args[4] if len(args) > 4 else "n?vim"

    if window is None:
        return
    if is_window_vim(window, vim_id):
        encoded = encode_key_mapping(key_mapping)
        window.write_to_child(encoded)
    else:
        boss.active_tab.neighboring_window(direction)
