from kittens.tui.handler import result_handler
from kitty.typing_compat import BossType


def main(*args, **kwargs):
    pass


@result_handler(no_ui=True)
def handle_result(
    args: list[str], result: str, target_window_id: int, boss: BossType
) -> str:
    return boss.active_tab.current_layout.name
