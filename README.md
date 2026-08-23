# SoundSys

Addon de áudio para Godot 4.4+. Gerencia música e efeitos sonoros através de
um autoload único (`SoundSys`), com biblioteca de SFX e playlists de música
carregadas a partir de um `AudioManifest`, buses de áudio dedicados
(`Music`/`SFX`) e troca automática de faixa ao final de cada música.

## Instalação

1. Copie a pasta `sound_system/` para `res://addons/` do seu projeto.
2. Ative o plugin em **Project > Project Settings > Plugins**.
3. O autoload `SoundSys` é registrado automaticamente pelo plugin.

## Uso

```gdscript
# Tocar um efeito sonoro
SoundSys.play_sfx_requested.emit("click")

# Tocar uma playlist de música
SoundSys.play_music_requested.emit("8_bit_jingles")

# Ajustar volume de um bus
SoundSys.apply_volume_to_bus("Music", 0.8)
```

### Sinais

| Sinal                                            | Descrição                                                |
| ------------------------------------------------ | -------------------------------------------------------- |
| `play_sfx_requested(sfx_key, bus, manager_node)` | Solicita a reprodução de um efeito sonoro da biblioteca. |
| `play_music_requested(music_key, manager_node)`  | Solicita a troca para uma playlist de música.            |
| `music_track_changed(music_key)`                 | Emitido quando a faixa de música muda.                   |
| `volume_changed(bus_name, linear_volume)`        | Emitido quando o volume de um bus é alterado.            |

## Estrutura

- `scripts/sound_sys.gd` — script principal do autoload.
- `scripts/sound_sys_plugin.gd` — script do `EditorPlugin` que registra o autoload.
- `scripts/audio_manifest.gd`, `scripts/generate_audio_manifest.gd` — geração do manifesto de áudio a partir dos assets.
- `resources/audio_manifest.tres` — manifesto com as bibliotecas de SFX e música.
- `assets/sfx/`, `assets/music/` — biblioteca de áudio incluída.
- `scenes/sound_sys.tscn` — cena do autoload.

## Licença

MIT — veja [LICENSE](LICENSE).
