extends Node
## All connection logic lives here (GAME_PLAN 9.5) so gameplay never depends on how
## peers connect. Solo = host with no peers. Real ENet code lands in M11.

const MAX_PEERS: int = 8
const DEFAULT_PORT: int = 7777

var is_online: bool = false


## True for the solo player and for a hosting player. Gameplay asks this, never
## "am I single player", so there is only one code path.
func is_host() -> bool:
	return not is_online or multiplayer.is_server()
