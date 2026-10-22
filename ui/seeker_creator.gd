extends Node

# V0.38: in-world appearance editor. Appearance is kept separate from the V0.33 quest save.
# Cosmetic choices are not an official character class, nation, or Seeker rank.
const SAVE_FILE: String = "user://margerina_appearance_v038.json"
const SKINS: Array[String] = ["Warm", "Deep", "Light", "Olive"]
const HAIRS: Array[String] = ["Short", "Spiky", "Topknot", "Cropped"]
const COATS: Array[String] = ["Seeker Blue", "Forest Green", "Night Black", "Crimson"]
const AURAS: Array[String] = ["Azure", "Gold", "Violet", "Jade"]

var player: CharacterBody3D
var panel: PanelContainer
var name_edit: LineEdit
var skin_option: OptionButton
var hair_option: OptionButton
var coat_option: OptionButton
var aura_option: OptionButton
var feedback: Label
var open_button: Button

func _ready() -> void:
    add_to_group("seeker_creator")
    call_deferred("_finish_setup")

func _finish_setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(player):
        push_warning("Seeker creator: player not ready")
        return
    _make_ui()
    _load_appearance()
    _apply_preview()

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "SeekerCreatorLayer"
    layer.layer = 12
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    open_button = Button.new()
    open_button.text = "LOOK"
    open_button.add_theme_font_size_override("font_size", 20)
    open_button.anchor_left = 1.0
    open_button.anchor_right = 1.0
    open_button.offset_left = -432.0
    open_button.offset_right = -329.0
    open_button.offset_top = 12.0
    open_button.offset_bottom = 65.0
    open_button.pressed.connect(_toggle_editor)
    root.add_child(open_button)

    panel = PanelContainer.new()
    panel.anchor_left = 0.23
    panel.anchor_right = 0.77
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.92
    panel.visible = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color(0.055, 0.08, 0.15, 0.97)
    background.border_color = Color(0.36, 0.67, 0.84)
    background.set_border_width_all(3)
    background.set_corner_radius_all(12)
    panel.add_theme_stylebox_override("panel", background)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 7)
    scroll.add_child(stack)
    _text(stack, "YOUR SEEKER - APPEARANCE", 25)
    _text(stack, "Cosmetic choices. All Seven Spokes remain available later.", 16)
    _text(stack, "NAME", 18)
    name_edit = LineEdit.new()
    name_edit.placeholder_text = "New Seeker"
    name_edit.max_length = 24
    name_edit.custom_minimum_size.y = 42
    name_edit.text_changed.connect(_on_look_changed)
    stack.add_child(name_edit)
    skin_option = _choice(stack, "SKIN TONE", SKINS)
    hair_option = _choice(stack, "HAIRSTYLE", HAIRS)
    coat_option = _choice(stack, "SEEKER CLOTHING", COATS)
    aura_option = _choice(stack, "AURA COLOR", AURAS)
    feedback = _text(stack, "Changes are shown on your Seeker immediately.", 16)
    var actions := HBoxContainer.new()
    stack.add_child(actions)
    var save_btn := Button.new()
    save_btn.text = "SAVE LOOK"
    save_btn.custom_minimum_size = Vector2(0, 49)
    save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    save_btn.pressed.connect(_save_appearance)
    actions.add_child(save_btn)
    var close_btn := Button.new()
    close_btn.text = "CLOSE"
    close_btn.custom_minimum_size = Vector2(0, 49)
    close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    close_btn.pressed.connect(_close_editor)
    actions.add_child(close_btn)

func _text(parent: Node, value: String, size: int) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
    parent.add_child(label)
    return label

func _choice(parent: VBoxContainer, caption: String, entries: Array[String]) -> OptionButton:
    _text(parent, caption, 18)
    var option := OptionButton.new()
    option.custom_minimum_size.y = 42
    for entry in entries:
        option.add_item(entry)
    option.item_selected.connect(_on_look_changed)
    parent.add_child(option)
    return option

func _toggle_editor() -> void:
    if is_open():
        _close_editor()
        return
    if not is_instance_valid(player):
        return
    # Don't interrupt sparring while standing within reach of training enemies.
    if player.global_position.z < -17.0:
        open_button.text = "USE IN HUB"
        return
    var hub: Node = get_tree().get_first_node_in_group("hub_manager")
    if is_instance_valid(hub) and bool(hub.call("_any_panel_open")):
        return
    panel.show()
    open_button.text = "CLOSE LOOK"
    if is_instance_valid(player):
        player.velocity.x = 0.0
        player.velocity.z = 0.0

func _close_editor() -> void:
    if is_instance_valid(panel):
        panel.hide()
    if is_instance_valid(open_button):
        open_button.text = "LOOK"

func _on_look_changed(_unused: Variant = null) -> void:
    _apply_preview()

func _apply_preview() -> void:
    if not is_instance_valid(player) or not is_instance_valid(skin_option):
        return
    var rig: Node = player.get_node_or_null("AnimatedSeeker")
    if is_instance_valid(rig) and rig.has_method("apply_player_appearance"):
        rig.call("apply_player_appearance", skin_option.selected, hair_option.selected, coat_option.selected, aura_option.selected)
    GameState.player_name = _clean_name(name_edit.text)

func _clean_name(value: String) -> String:
    var cleaned: String = value.strip_edges().replace("\n", " ").replace("\r", " ")
    return cleaned if cleaned.length() > 0 else "New Seeker"

func _save_appearance() -> void:
    _apply_preview()
    var data := {
        "version": 1,
        "name": GameState.player_name,
        "skin": skin_option.selected,
        "hair": hair_option.selected,
        "coat": coat_option.selected,
        "aura": aura_option.selected
    }
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        feedback.text = "Could not save look. Check browser site storage."
        return
    file.store_string(JSON.stringify(data))
    file.close()
    feedback.text = "Seeker appearance saved on this browser."

func _load_appearance() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        name_edit.text = GameState.player_name
        return
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return
    var value: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(value) != TYPE_DICTIONARY:
        return
    var data: Dictionary = value
    if int(data.get("version", 0)) != 1:
        return
    name_edit.text = str(data.get("name", "New Seeker")).substr(0, 24)
    skin_option.select(clampi(int(data.get("skin", 0)), 0, SKINS.size() - 1))
    hair_option.select(clampi(int(data.get("hair", 0)), 0, HAIRS.size() - 1))
    coat_option.select(clampi(int(data.get("coat", 0)), 0, COATS.size() - 1))
    aura_option.select(clampi(int(data.get("aura", 0)), 0, AURAS.size() - 1))
