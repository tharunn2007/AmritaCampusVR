import bpy, json, pathlib
from mathutils import Vector
root=pathlib.Path(__file__).resolve().parents[1]
objects=[]
for o in bpy.context.scene.objects:
 if o.type=='MESH':
  corners=[o.matrix_world@Vector(c) for c in o.bound_box]
  objects.append(dict(name=o.name,vertices=len(o.data.vertices),min=[min(c[i] for c in corners) for i in range(3)],max=[max(c[i] for c in corners) for i in range(3)]))
(root/'assets/model_report.json').write_text(json.dumps(objects,indent=2))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/campus.glb'),export_format='GLB',export_cameras=False,export_lights=False,export_animations=False)
print('EXPORT_DONE',len(objects),sum(o['vertices'] for o in objects))
