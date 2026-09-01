
@tool
extends SceneTree
func _init():
    var env = Environment.new()
    for p in env.get_property_list():
        if 'fog' in p.name:
            print(p.name, ' -> type: ', p.type)
    quit()
